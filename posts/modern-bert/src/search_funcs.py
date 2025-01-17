import torch
import numpy as np
import os
import pickle


class RetrieveReranker:
    def __init__(
        self,
        corpus,
        bi_encoder_model,
        cross_encoder_model,
        save_corpus=False,
        corpus_path=None,
    ):
        self.bi_encoder_model = bi_encoder_model
        self.cross_encoder_model = cross_encoder_model
        self.save_corpus = save_corpus
        self.corpus_path = corpus_path

        self.corpus = corpus  # raw text
        self.corpus_embed = self._embed_corpus()  # embedded text

    def _embed_corpus(self):
        "Embed and save a corpus of searchable text, or load corpus if present"
        embedding = None

        try:
            if os.path.exists(self.corpus_path):
                embedding = self._load_corpus()
            else:
                embedding = self.bi_encoder_model.encode(self.corpus)

                if self.save_corpus:
                    self._save_corpus(embedding)

        except Exception as e:
            print(f"Error processing corpus: {e}")

        return embedding

    def _save_corpus(self, embedding):
        with open(self.corpus_path, "wb") as fOut:
            pickle.dump(embedding, fOut)

    def _load_corpus(self):
        with open(self.corpus_path, "rb") as fIn:
            return pickle.load(fIn)

    def query(self, query_string, number_ranks=100, number_results=1):
        "Find the top N results matching the input string"
        N = number_ranks

        # embed query in bi-enocder, then get cosine similarities w/ corpus
        query_embed = self.bi_encoder_model.encode(query_string)
        sims = self.bi_encoder_model.similarity(query_embed, self.corpus_embed)
        idx = np.array(torch.topk(sims, N).indices)[0]

        # create a list of paired strings
        ce_list = []

        for i in idx:
            ce_list.append([query_string, self.corpus[i]])

        # run cross-encoder
        scores = self.cross_encoder_model.predict(ce_list)
        scores_idx = scores.argmax()

        return ce_list[scores_idx][1]
