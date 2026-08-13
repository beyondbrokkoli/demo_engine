# ingest_embeddings.py
import requests
from ingest_config import LOCAL_EMBED_URL, LOCAL_API_KEY

def get_embedding(text):
    headers = {
        "Authorization": f"Bearer {LOCAL_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {"input": text}
    response = requests.post(LOCAL_EMBED_URL, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()["data"][0]["embedding"]
