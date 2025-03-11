"Functions for RAG embedding, indexing"

import faiss
import pickle
import re
import numpy as np
from sentence_transformers import SentenceTransformer
from .keyterms import keyterms

# embedding model
MODEL = "all-mpnet-base-v2"


# functions for structured text extraction
def extract_pages(pdf_reader, page_start, page_end):
    "Extract and concatenate selected pages from a pdf"
    text = ""
    for page in range(page_start, page_end):
        text += pdf_reader.pages[page].extract_text() + "\n"

    return text


def search_rules(query, index, chunks, top_k=5):
    # Load the model (same as used for encoding)
    model = SentenceTransformer(MODEL)

    # Encode the query
    query_embedding = model.encode([query])[0].reshape(1, -1).astype("float32")

    # Search the index
    distances, indices = index.search(query_embedding, top_k)

    # Retrieve the corresponding chunks
    results = []
    for i, idx in enumerate(indices[0]):
        results.append(
            {
                "chunk": chunks[idx],
                "score": 1.0
                / (1.0 + distances[0][i]),  # Convert distance to similarity score
            }
        )

    return results


## AI ALERT ##
## CODE BELOW IS ABOUT 85% CLAUDE GENERATED ##


def chunk_by_subsections_with_codes(text):
    # Pattern that handles section numbers plus the variable code format
    pattern = r"(\d+\.\d+\.\d+\s+[\w\s]+(?::\s*[A-Za-z_/]+)?)"

    # Split the text by the subsection headers
    split_sections = re.split(pattern, text)

    # Recombine headers with their content
    chunks = []
    for i in range(1, len(split_sections), 2):
        if i < len(split_sections) - 1:
            # Combine header with the content that follows
            section_header = split_sections[i]
            section_content = split_sections[i + 1]

            # Extract section number for metadata
            section_number = re.match(r"(\d+\.\d+\.\d+)", section_header).group(1)

            # Create chunk with metadata
            chunk = {
                "text": section_header + section_content,
                "section_number": section_number,
                "section_title": section_header.strip(),
            }
            chunks.append(chunk)

    return chunks


def encode_chunks(chunks, batch_size=8):
    # Load a lightweight but effective model
    model = SentenceTransformer(MODEL)

    # Extract just the text for encoding
    texts = [chunk["text"] for chunk in chunks]

    # Process in batches to manage memory
    all_embeddings = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        batch_embeddings = model.encode(batch)
        all_embeddings.append(batch_embeddings)

    # Combine batches
    embeddings = np.vstack(all_embeddings)

    # Add embeddings to our chunks
    for i, chunk in enumerate(chunks):
        chunk["embedding"] = embeddings[i]

    return chunks


def create_vector_store(encoded_chunks, output_dir=""):
    # Extract embeddings
    embeddings = np.array([chunk["embedding"] for chunk in encoded_chunks]).astype(
        "float32"
    )

    # Create a FAISS index
    dimension = embeddings.shape[1]  # Get embedding dimension
    index = faiss.IndexFlatL2(dimension)  # Using L2 distance (Euclidean)
    index.add(embeddings)

    # Save the index
    faiss.write_index(index, f"{output_dir}rules_index.faiss")

    # Save the chunks separately (without embeddings to save space)
    chunks_for_storage = []
    for i, chunk in enumerate(encoded_chunks):
        # Create a copy without the embedding to save storage
        chunk_copy = chunk.copy()
        del chunk_copy["embedding"]  # Remove embedding from storage copy
        chunk_copy["index"] = i  # Add index for retrieval
        chunks_for_storage.append(chunk_copy)

    # Save chunks with metadata
    with open(f"{output_dir}rule_chunks.pkl", "wb") as f:
        pickle.dump(chunks_for_storage, f)

    return index, chunks_for_storage


def search_rules(query, index, chunks, top_k=5):
    # Load the model (same as used for encoding)
    model = SentenceTransformer(MODEL)

    # Encode the query
    query_embedding = model.encode([query])[0].reshape(1, -1).astype("float32")

    # Search the index
    distances, indices = index.search(query_embedding, top_k)

    # Retrieve the corresponding chunks
    results = []
    for i, idx in enumerate(indices[0]):
        results.append(
            {
                "chunk": chunks[idx],
                "score": 1.0
                / (1.0 + distances[0][i]),  # Convert distance to similarity score
            }
        )

    return results


def search_vector_database(input_text, number_matches, vector_index, vector_database):
    index = faiss.read_index(vector_index)
    with open(vector_database, "rb") as file:
        chunks = pickle.load(file)
    model = SentenceTransformer(MODEL)

    # Improved approach
    rules_list = []
    matched_variables = {}

    for variable, config in keyterms.items():
        # Pattern matching with word boundaries and capturing context
        # just try 30 characters on either side to avoid including too much irrelevent text
        pattern = (
            r"(.{0,30})\b("
            + "|".join(map(re.escape, config["Terms"]))
            + r")\b(.{0,30})"
        )

        # Find all matches
        all_matches = re.finditer(pattern, input_text, re.IGNORECASE)
        variable_evidence = []

        for match in all_matches:
            full_match = match.group(0).strip()
            matched_term = match.group(2)  # term that matched
            variable_evidence.append(
                {"context": full_match, "matched_term": matched_term}
            )

        if variable_evidence:
            matched_variables[variable] = {
                "present": True,
                "evidence": variable_evidence,
            }

            # Use the best context for vector search
            # Append a heading to give better context to the section header
            best_context = variable_evidence[0]["context"]
            query_text = f"{config['Query']}: {best_context}"
            query_embedding = model.encode(query_text)

            # Add vector normalization for better results
            normalized_query = query_embedding / np.linalg.norm(query_embedding)
            distances, indices = index.search(
                normalized_query.reshape(1, -1), number_matches
            )

            # Track relevance scores and deduplicate
            seen_chunks = set()
            variable_rules = []

            for i, idx_array in enumerate(indices):
                for j, idx in enumerate(idx_array):
                    if idx not in seen_chunks:
                        seen_chunks.add(idx)
                        score = 1.0 / (1.0 + distances[i][j])

                        # Include metadata with the chunk
                        chunk_with_metadata = {
                            "text": chunks[idx]["text"],
                            "section_number": chunks[idx].get(
                                "section_number", "Unknown"
                            ),
                            "relevance_score": score,
                            "variable": variable,
                        }
                        variable_rules.append(chunk_with_metadata)

            # Sort by relevance and append
            variable_rules.sort(key=lambda x: x["relevance_score"], reverse=True)
            rules_list.extend(variable_rules)

    # Final sorting of all rules by relevance
    rules_list.sort(key=lambda x: x["relevance_score"], reverse=True)

    return rules_list, matched_variables


def create_prompt_rules(rules_list, matched_variables):
    PROMPT_RULES = """
If present, use the following rules to guide your coding of variables. Closely follow these instructions:
    - Apply ONLY the rules relevant to the question
    - If a rule is not relevant to the question, disregard it entirely
    - Do NOT try and apply rules to questions where they are not closely relevant
"""

    if not rules_list:
        PROMPT_RULES += "\n" + "NO RULES PRESENT"
    else:
        # Group rules by variable for better organization
        rules_by_variable = {}
        for rule in rules_list:
            variable = rule["variable"]
            if variable not in rules_by_variable:
                rules_by_variable[variable] = []
            rules_by_variable[variable].append(rule)

        # Add rules organized by variable
        for variable, variable_rules in rules_by_variable.items():
            PROMPT_RULES += f"\n\n## RULES FOR {variable}:\n"

            # Add the evidence that triggered this variable
            if variable in matched_variables:
                evidence = matched_variables[variable]["evidence"]
                evidence_text = ", ".join([f'"{e["context"]}"' for e in evidence[:2]])
                PROMPT_RULES += f"Evidence found: {evidence_text}\n\n"

            # Add the actual rules, with section numbers
            for i, rule in enumerate(
                variable_rules[:2]
            ):  # Limit to top 2 rules per variable
                section_info = f"Section {rule.get('section_number', 'Unknown')}"
                PROMPT_RULES += f"RULE {i+1} [{section_info}]:\n{rule['text']}\n\n"

    return PROMPT_RULES
