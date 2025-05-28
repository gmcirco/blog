"""Code to submit batch output to OpenAI API"""

import re
import pandas as pd
import json
import numpy as np
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from sentence_transformers import SentenceTransformer, util
from openai import OpenAI
from datetime import datetime


# setup openai creds
client = OpenAI()

neiss_data = r"C:\Users\gioc4\Documents\blog\data\neiss2024.csv"
neiss_codes = r"C:\Users\gioc4\Documents\blog\data\us-national-electronic-injury-surveillance-system-neiss-product-codes.json"

RUN_DATE = datetime.now().strftime("%Y-%m-%d")
NUM_NARRATIVES = 500
RAG_MODEL = SentenceTransformer("all-mpnet-base-v2")
MODEL = "gpt-4o-mini"
ROLE = """You are an expert medical grader. Your goal is to read incident narratives and 
extract structured output based on the information available in the narrative field. Your
PRIMARY GOAL is to determine the product that is MOST PROXIMATE to the injury reported in
the narrative. You MUST choose only from the provided list of products and return the 
EXACT product name and produce code in your answer.
"""

# parameters for rag
# define regex to extract the core narrative for RAG
# max number of products per-phrase
# minimum matching score (cosine sim)
CORE_NARRATIVE_REGEX = re.compile("\d{1,3}\s?[A-Z]{2,4}[,]?\s+(.*?)(?=\s*DX:)")
RAG_MAX_PRODUCTS = 10
RAG_MIN_MATCH = 0.35

# stopwords for parsing phrases
STOPWORDS = set(stopwords.words("english"))

def load_product_codes(path_to_file):
    with open(path_to_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data

def extract_core_narrative(neiss_narrative):
    match = CORE_NARRATIVE_REGEX.search(neiss_narrative)

    if match:
        return match.group(1).strip()
    else:
        return neiss_narrative


def load_neiss_data(path_to_file, max=5):
    dataframe = pd.read_csv(path_to_file)
    json_output = dataframe[:max].to_json(lines=True, orient="records")
    return [line for line in json_output.strip().split("\n") if line]


def get_narrative(neiss_json):
    narrative = json.loads(neiss_json)
    return narrative["Narrative_1"]


def get_id(json_str):
    neiss_json = json.loads(json_str)
    return neiss_json["CPSC_Case_Number"]

# RAG STUFF HERE
# MOSTLY CHAT-GPT GENERATED WITH SOME HUMAN EDITS
def extract_phrases(text, max_n=3):
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", "", text)
    tokens = [t for t in word_tokenize(text) if t not in STOPWORDS]

    phrases = set()
    for n in range(1, max_n + 1):
        for i in range(len(tokens) - n + 1):
            phrase = " ".join(tokens[i : i + n])
            if phrase.strip():
                phrases.add(phrase)

    return list(phrases)

def match_phrases_to_products(phrases, embeddings, products):
    if not phrases:
        return ["9999 - UNCATEGORIZED PRODUCT"]

    # Batch encode all phrases at once
    phrase_embeddings = RAG_MODEL.encode(phrases, convert_to_tensor=True)
    
    # Compute cosine similarity in one go
    similarity = util.cos_sim(phrase_embeddings, embeddings).cpu().numpy()

    results = []
    for i, scores in enumerate(similarity):
        top_indices = np.argsort(scores)[::-1][:RAG_MAX_PRODUCTS]
        matches = [
            f"{products[j]['code']} - {products[j]['product_title']}"
            for j in top_indices
            if scores[j] >= RAG_MIN_MATCH
        ]
        if matches:
            results.append({"term": phrases[i], "matches": matches})

    return results


def extract_unique_matches_as_string(results):
    seen = set()
    unique_matches = []

    for entry in results:
        for match in entry["matches"]:
            if match not in seen:
                seen.add(match)
                unique_matches.append(match)

    unique_matches.sort()

    return "\n".join(unique_matches)

# Set up prompt
def create_prompt(neiss_incident, neiss_product_codes):

    prompt = f"""Closely follow the numbered instructions to perform your evaluation of the narrative.

        ## NARRATIVE
        1. Read the following injury report narrative:

        {neiss_incident}

        ## PRODUCT LIST

        2. Review the following list of products to choose from:

        Products are listed in the format [code] - [product]

        {neiss_product_codes}

        ## INSTRUCTIONS

        3. Identify the primary injury listed in the narrative
        4. Identify the product from the provided product list that is MOST PROXIMATE to the primary injury
        5. Provide the name of the product AND the product code in your answer
        6. Return your answer as a JSON object, following the format below EXACTLY:

        {{"primary_injury": [injury], "product": [product], "product_code": [product_code]}}

        5. Review the following examples and follow the format closely in your output.

        ## EXAMPLE 1
        '13YOM REPORTS HE WAS GETTING INTO THE SHOWER WHEN HE SLIPPED AND FELL ON HIS SIDE AND HEARD A POP IN HIS FOOT. DX ACHILLES TENDON INJURY'
        {{"primary_injury": "DX ACHILLES TENDON INJURY", "product": "BATHTUBS OR SHOWERS", "product_code": 611}}

        ## EXAMPLE 2
        '36YOM REPORTS WITH KNEE PAIN AFTER FALLING OFF AN ELECTRIC SCOOTER. DX KNEE ABRASION'
        {{"primary_injury": "KNEE ABRASION", "product": "SCOOTERS, POWERED", "product_code": 5022}}

        ## EXAMPLE 3
        '76YOF WAS WALKING INTO A BUILDING AND TRIPPED OVER A DOOR JAM AND FELL. PAIN TO HIPS, RIGHT KNEE AND RIGHT WRIST. DX: PAIN KNEE RIGHT, PAIN WRIST RIGHT, PAIN HIP LEFT'
        {{"primary_injury": "PAIN KNEE RIGHT, PAIN WRIST RIGHT, PAIN HIP LEFT", "product": "DOOR SILLS OR FRAMES", "product_code": 1878}}

        ## EXAMPLE 4
        '67YOM FELL OUT OF CHAIR AND HAVING ALTERED MENTAL STATUS. DX FALL NO INJURY'
        {{"primary_injury": "FALL NO INJURY", "product": "CHAIRS, OTHER OR NOT SPECIFIED", "product_code": 4074}}

        ## EXAMPLE 5
        '48YOM WAS ATTEMPTING TO GET OUT OF BED AND FELT VERY DIZZY AND FELL DX: CLOSED HEAD INJURY VERTIGO'
        {{"primary_injury": "CLOSED HEAD INJURY VERTIGO", "product": "BEDS OR BEDFRAMES, OTHER OR NOT SPECIFIED", "product_code": 4076}}
        """
    
    return prompt


# get NEISS narratives
neiss_json = load_neiss_data(neiss_data, NUM_NARRATIVES)
product_codes = load_product_codes(neiss_codes)

# set up vector db for rag
products = load_product_codes(neiss_codes)

# Precompute product description embeddings
product_texts = [p["product_title"] for p in products]
product_embeddings = RAG_MODEL.encode(product_texts, convert_to_tensor=True)

# func to loop, add rag to prompt
def create_prompt_with_rag(neiss_json):
    neiss_narrative = get_narrative(neiss_json)
    neiss_product_narrative = extract_core_narrative(neiss_narrative)
    phrases = extract_phrases(neiss_product_narrative)
    codes = match_phrases_to_products(phrases, product_embeddings, product_codes)
    code_str = extract_unique_matches_as_string(codes)
    
    return create_prompt(neiss_narrative, code_str)

# now loop through whole process, fill up jsonl
json_list = []

for narrative in neiss_json:
    id = get_id(narrative)
    prompt = create_prompt_with_rag(narrative)

    json_list.append(
        {
            "custom_id": f"{id}",
            "method": "POST",
            "url": "/v1/chat/completions",
            "body": {
                "model": MODEL,
                "messages": [
                    {"role": "system", "content": ROLE},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 100,
                "temperature": 0.1,
                "response_format": {"type": "json_object"},
            },
        }
    )

with open(f"json/output_{RUN_DATE}.jsonl", "w") as outfile:
    for entry in json_list:
        json.dump(entry, outfile)
        outfile.write("\n")

# upload batch to openai
batch_input_file = client.files.create(
    file=open(f"json/output_{RUN_DATE}.jsonl", "rb"), purpose="batch"
)

batch_input_file_id = batch_input_file.id
client.batches.create(
    input_file_id=batch_input_file_id,
    endpoint="/v1/chat/completions",
    completion_window="24h",
    metadata={"description": f"Testing {NUM_NARRATIVES} NEISS narratives"},
)
