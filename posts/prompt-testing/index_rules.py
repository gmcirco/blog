"Code to index rules from the NVDRS and store as vector store in cache"

from pypdf import PdfReader
from src.rag import (
    extract_pages,
    chunk_by_subsections_with_codes,
    encode_chunks,
    create_vector_store,
)

# import the full nvdrs coding manual
# we only need a subset of pages on circumstances
# page 74 - 149
page_min = 74
page_max = 148
cache_dir = "cache/"

reader = PdfReader("reference/nvdrsCodingManual.pdf")

# extract pages, chunk subsections, then store in cache

pages_circumstances = extract_pages(reader, page_min, page_max)
section_circumstances = chunk_by_subsections_with_codes(pages_circumstances)
section_embeddings = encode_chunks(section_circumstances)
index, stored_chunks = create_vector_store(section_embeddings, cache_dir)
