# Agent with RAG tooling built with LangChain, OpenAI, Node, Google Search API, AWS, and Terraform.

## Could be used as a starting point for AI agent development.

### Run the API locally

* `cd` into the `/api` directory
* execute `uv run uvicorn main:app --reload` to start the API
* you can find the API docs at `http://localhost:8000/docs`
* you can test the streaming by running the `api-test.ipynb` notebook