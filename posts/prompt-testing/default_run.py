import pandas as pd
import json
from datetime import datetime

from openai import OpenAI
from src.prompts import HEADER1, BODY1, BODY2, EXAMPLE_OUTPUT1, EXAMPLE_OUTPUT2
from src.prompt_creation import Prompt

client = OpenAI()
run_date = datetime.now().strftime("%Y-%m-%d")

# set up prompt
prompt_creator = Prompt()
ROLE = """You are a mental health expert reviewing law enforcement narratives of youth suicide incidents. 
Your task is to label variables relating to the incident. Closely review the following instructions. Read 
the provided narrative and then add labels corresponding to the variables into the described JSON format. 
Do NOT deviate from the instructions.
"""

# load suicide narratives and labels
narratives = pd.read_csv("data/train_narratives_sample_200.csv")
labels = pd.read_csv("data/train_labels_sample_200.csv")

# Execute 4 versions of prompts
# 0. default copy-and-paste from contest instructions
# 1. Add 3 few-shot examples
# 2. Add more descriptions to variables
# 3. Few-shot and more descriptions

json_list = []

for row in narratives.iterrows():

    # grab the unique id and text
    single_narrative = row[1]
    id = single_narrative["uid"]
    txt = single_narrative["NarrativeLE"]

    prompt_input = {
        "header": HEADER1,
        "narrative": txt,
        "body": [BODY1, BODY2],
        "example_output": [EXAMPLE_OUTPUT1, EXAMPLE_OUTPUT2],
        "footer": None,
    }

    # create a prompt, pass in the text narrative
    prompt_versions = prompt_creator.standard_prompt_caching(**prompt_input)

    version_num = 0
    for prompt in prompt_versions:
        # now append to list
        json_list.append(
            {
                "custom_id": f"{id}_{version_num}",
                "method": "POST",
                "url": "/v1/chat/completions",
                "body": {
                    "model": "gpt-4o-mini",
                    "messages": [
                        {"role": "system", "content": ROLE},
                        {"role": "user", "content": prompt},
                    ],
                    "max_tokens": 500,
                    "response_format": { "type": "json_object" },
                },
            }
        )
        version_num += 1


with open(f"json/output_{run_date}.jsonl", "w") as outfile:
    for entry in json_list:
        json.dump(entry, outfile)
        outfile.write("\n")

# upload batch to openai
batch_input_file = client.files.create(
    file=open(f"json/output_{run_date}.jsonl", "rb"), purpose="batch"
)

batch_input_file_id = batch_input_file.id
client.batches.create(
    input_file_id=batch_input_file_id,
    endpoint="/v1/chat/completions",
    completion_window="24h",
    metadata={"description": "Batch Testing 1 prompts x 200 examples with caching and RAG"},
)
