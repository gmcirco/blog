"""Code to submit batch output to OpenAI API"""

import json
import pandas as pd
import os
from openai import OpenAI
import json
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer
from datetime import datetime
import re


# setup openai creds
client = OpenAI()

neiss_data = r"C:\Users\gioc4\Documents\blog\data\neiss2024.csv"
neiss_codes = r"C:\Users\gioc4\Documents\blog\data\us-national-electronic-injury-surveillance-system-neiss-product-codes.json"

RUN_DATE = datetime.now().strftime("%Y-%m-%d")
NUM_NARRATIVES = 10
RAG_MODEL = SentenceTransformer("all-mpnet-base-v2")
MODEL = "gpt-4o-mini"
ROLE = """You are an expert medical grader. Your goal is to read incident narratives and 
extract structured output based on the information available in the narrative field. Your
PRIMARY GOAL is to determine the product that is MOST PROXIMATE to the injury reported in
the narrative. You MUST choose only from the provided list of products and return the 
EXACT product name and produce code in your answer.
"""

# define regex to extract the core narrative for RAG
CORE_NARRATIVE_REGEX = re.compile("\d{1,3}\s?[A-Z]{2,4}[,]?\s+(.*?)(?=\s*DX:)")


class NEISSVectorDB:
    def __init__(self, products, model):
        self.products = products
        self.model = model
        self.product_embeddings = None
        self.create_embeddings()

    def create_embeddings(self):
        """Create vector embeddings for all product titles"""
        product_titles = [p["product_title"] for p in self.products]
        self.product_embeddings = self.model.encode(product_titles)
        print(f"Created embeddings for {len(product_titles)} NEISS products")

    def find_closest_product(self, query_product, top_k=3):
        """Find the closest NEISS product(s) for a given query product"""
        # Convert query to embedding
        query_embedding = self.model.encode([query_product])

        # Calculate similarity with all product embeddings
        similarities = cosine_similarity(query_embedding, self.product_embeddings)[0]

        # Get top k matches
        top_indices = np.argsort(similarities)[::-1][:top_k]

        matches = []
        for idx in top_indices:
            matches.append(
                {
                    "code": self.products[idx]["code"],
                    "product_title": self.products[idx]["product_title"],
                    "similarity": similarities[idx],
                }
            )

        return matches


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


def create_prompt(neiss_incident, neiss_product_codes):

    prompt = f"""Closely follow the numbered instructions to perform your evaluation of the narrative.

        ## NARRATIVE
        1. Read the following injury report narrative:

        {neiss_incident}

        ## PRODUCT LIST

        2. Review the following list of products to choose from:

        Products are listed in the format [code] [product]

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
        """

    return prompt


# get  NEISS narratives
neiss_json = load_neiss_data(neiss_data, NUM_NARRATIVES)
product_codes = load_product_codes(neiss_codes)

# set up vector db for rag
vector_db = NEISSVectorDB(product_codes, RAG_MODEL)

# func to loop add rag to prompt
def create_prompt_with_rag(neiss_json, rag_top_n=50):
    neiss_narrative = get_narrative(neiss_json)
    neiss_product_narrative = extract_core_narrative(neiss_narrative)
    codes = vector_db.find_closest_product(neiss_product_narrative, rag_top_n)

    # construct the rag addition
    code_str = ""
    for code in codes:
        code_str += f"\n{code['code']} {code['product_title']}"

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
