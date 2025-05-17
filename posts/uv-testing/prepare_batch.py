"""Code to submit batch output to OpenAI API"""

import json
import pandas as pd
from openai import OpenAI
import json
from datetime import datetime

# setup openai creds
client = OpenAI()

neiss_data = r"C:\Users\gioc4\Documents\blog\data\neiss2024.csv"

RUN_DATE = datetime.now().strftime("%Y-%m-%d")
NUM_NARRATIVES = 500
MODEL = "gpt-4.1"
ROLE = """You are an expert medical grader. Your goal is to read incident narratives and 
extract structured output based on the information available in the narrative field. Your
PRIMARY GOAL is to determine the product that is MOST PROXIMATE to the injury reported in
the narrative.
"""


def load_neiss_data(path_to_file, max=5):
    dataframe = pd.read_csv(path_to_file)
    json_output = dataframe[:max].to_json(lines=True, orient="records")
    return [line for line in json_output.strip().split("\n") if line]


def get_id(json_str):
    neiss_json = json.loads(json_str)
    return neiss_json["CPSC_Case_Number"]


def create_prompt(neiss_incident):

    prompt = f"""Closely follow the numbered instructions to perform your evaluation of the narrative.

        ## NARRATIVE
        1. Read the following injury report narrative:

        {neiss_incident}

        ## INSTRUCTIONS

        2. Identify the primary injury listed in the narrative
        3. Identify the product that is MOST PROXIMATE to the primary injury
        4. Return your answer as a JSON object, following the format below EXACTLY:

        {{"primary_injury": [injury], "product": [product]}}

        5. Review the following examples and follow the format closely in your output.

        ## EXAMPLE 1
        '17YOM, ACCIDENTALLY DROPPED 25LB WEIGHT ON HIS FOOT WHILE WORKING OUT IN THE GYM, DX: CRUSHING INJURY OF TOE OF LEFT FOOT'
        {{"primary_injury": "CRUSHING INJURY OF TOE", "product": "25LB WEIGHT"}}

        ## EXAMPLE 2
        '55YOM  HIT DOOR JAM W TOE  THAT IS SWOLLEN AND PAINFULL .  DX  CONTUSION OF 5TH TOE'
        {{"primary_injury": "CONTUSION OF TOE", "product": "DOOR"}}

        ## EXAMPLE 3
        '76YOF HAD A FALL TO THE FLOOR AT THE NURSING HOME ONTO HEAD DX SUBDURAL HEMATOMA'
        {{"primary_injury": "SUBDURAL HEMATOMA", "product": "FLOOR"}}

        ## EXAMPLE 4
        '89YOF, FEELING DIZZY, STOOD UP AND BEGAN WALKING WITH THE WALKER WHEN COLLAPSED AND FELL STRIKING HEAD ONTO A CHAIR, NO LOSS OF CONSCIOUS/BLOOD THINNERS, DX: FALL, INTIAL ENCOUNTER, AKI; UTI W/O HEMATURIA
        {{"primary_injury": "HEAD INJURY, FALL", "product": "CHAIR"}}
        """

    return prompt


# get  NEISS narratives
neiss_json = load_neiss_data(neiss_data, NUM_NARRATIVES)

json_list = []

for narrative in neiss_json:
    id = get_id(narrative)
    prompt = create_prompt(narrative)

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
