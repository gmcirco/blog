from itertools import product
from src.rag import create_prompt_rules, search_vector_database


class Prompt:
    def __init__(self):
        pass

    def prompt_concat(self, text_list):
        """Concat a list of text, dropping None values"""
        output_text = "\n".join(filter(None, text_list))
        output_text += "\n"

        return output_text

    def standard_prompt(
        self,
        header: str | list = None,
        narrative: str | list = None,
        body: str | list = None,
        example_output: str | list = None,
        footer: str | list = None,
        **kwargs
    ) -> list:
        """Create multiple standard prompts based on all combinations of list elements."""

        # Ensure all inputs are lists for consistent iteration
        params = [header, narrative, body, example_output, footer]
        param_lists = [
            [item] if not isinstance(item, list) else item for item in params
        ]

        # unpack params, then pass to concat
        prompt_combinations = product(*param_lists)
        prompts = [
            self.prompt_concat(combination) for combination in prompt_combinations
        ]

        return prompts

    def standard_prompt_caching(
        self,
        header: str | list = None,
        narrative: str | list = None,
        body: str | list = None,
        example_output: str | list = None,
        footer: str | list = None,
        include_rag: bool | list = False,
        **kwargs
    ) -> list:
        """Create multiple standard prompts based on all combinations of list elements.
        This puts the narrative at the end to support OpenAI prompt caching.
        """

        # Ensure all inputs are lists for consistent iteration
        if include_rag:
            val, matched_variables = search_vector_database(
                narrative,
                2,
                "cache/rules_index.faiss",
                "cache/rule_chunks.pkl",
            )
            rag = create_prompt_rules(val, matched_variables)
            params = [body, example_output, rag, footer, header, narrative]
        else:
            params = [body, example_output, footer, header, narrative]
        param_lists = [
            [item] if not isinstance(item, list) else item for item in params
        ]

        # unpack params, then pass to concat
        prompt_combinations = product(*param_lists)
        prompts = [
            self.prompt_concat(combination) for combination in prompt_combinations
        ]

        return prompts

    def unstructured_prompt(self, prompt_text_list: list[str]) -> str:
        """Create an unstructured prompt, given a list of text"""
        return self.prompt_concat([prompt_text_list])
