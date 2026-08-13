# rag_embeddings.py
import requests
from rag_config import LOCAL_EMBED_URL, LOCAL_EMBED_API_KEY

def get_query_vector(text):
    """Generates a query embedding vector natively via local Nomic server."""
    headers = {
        "Authorization": f"Bearer {LOCAL_EMBED_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {"input": text}
    response = requests.post(LOCAL_EMBED_URL, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()['data'][0]['embedding']
