import os
import sys
import requests
from qdrant_client import QdrantClient
from openai import OpenAI

# --- Configuration ---
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"

# Local Embeddings (Kept local since Hetzner has no /v1/embeddings)
LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_API_KEY = "TEST1234"

# --- Hetzner API Configuration ---
HETZNER_LLM_URL = "https://inference.hetzner.com/api/v1/chat/completions"
HETZNER_API_KEY = os.getenv("HETZNER_API_KEY")

# Options:
# - "Kimi-K2.7-Code" (Tailored for code execution & logic)
# - "Qwen/Qwen3.6-35B-A3B-FP8" (Very fast, highly accurate C/systems knowledge)
# - "DeepSeek-V4-Flash-0731" (512k context window for huge retrieval dumps)
#HETZNER_MODEL = "Kimi-K2.7-Code"
HETZNER_MODEL = "Qwen/Qwen3.6-35B-A3B-FP8"

qdrant = QdrantClient(url=QDRANT_URL)

def get_query_vector(text):
    """Generates a query embedding vector natively via local server."""
    headers = {
        "Authorization": f"Bearer {LOCAL_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {"input": text}
    response = requests.post(LOCAL_EMBED_URL, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()['data'][0]['embedding']

def search_codebase(query, limit=12):
    """Queries Qdrant for relevant modules and formats dependency metadata."""
    query_vector = get_query_vector(query)
    results = qdrant.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        limit=limit
    )

    contexts = []
    print("\n📚 [RETRIEVAL] Qdrant pulled the following context:")
    for point in results.points:
        payload = point.payload
        deps = payload.get('dependencies', [])
        deps_str = ", ".join(deps) if deps else "None (Level 0 / Root)"

        print(f"   -> {payload['file']} (Score: {point.score:.4f})")

        contexts.append(
            f"--- FILE: {payload['file']} ---\n"
            f"DEPENDENCIES: {deps_str}\n"
            f"CONTENT:\n{payload['content']}"
        )
    return "\n\n".join(contexts)

def ask_llm(query, context):
    """Sends the retrieved context and question to Hetzner's API using the OpenAI SDK."""
    system_prompt = (
        "You are the Lead Systems Architect for the Weaver Engine. You are performing a rigorous "
        "'needle-in-a-haystack' codebase audit. You will be provided with a massive context of C "
        "source files and dependency mappings. Your task is to locate the exact mechanisms asked "
        "about by the user and explain them with absolute structural precision.\n\n"
        "CRITICAL DIRECTIVES:\n"
        "1. EXHAUSTIVE SEARCH: The context is large. You must mentally scan ALL provided files "
        "before formulating your answer. Do not stop at the first partial match.\n"
        "2. ZERO HALLUCINATION: Base your entire response ONLY on the provided text. Do not invent "
        "C functions, structs, pointers, or architectural concepts that are not explicitly written "
        "in the provided snippets. Ignore your pre-trained knowledge of C or game engines.\n"
        "3. EXPLICIT CITATION: Every technical claim, data flow step, or logic explanation MUST "
        "cite the exact source file in brackets, e.g., 'The memory pool is initialized in [memory_core.c].'\n"
        "4. MISSING DATA: If the provided context does not contain the complete answer, do not guess. "
        "You MUST state exactly: 'The provided context does not contain sufficient material to map this architecture.'\n\n"
        "EXECUTION FORMAT:\n"
        "Always begin your response with a <scratchpad> block. Inside this block, list the files "
        "that contain relevant code and briefly note what they contain. Once your map is complete, "
        "close the scratchpad and write your final architectural analysis."
        "Keep scratchpad reasoning brief."
    )

    user_prompt = f"RETRIEVED CODE CONTEXT:\n{context}\n\nUSER QUESTION:\n{query}"

    client = OpenAI(
        base_url="https://inference.hetzner.com/api/v1",
        api_key=HETZNER_API_KEY,
    )

    print(f"\n🤖 Hetzner ({HETZNER_MODEL}) is thinking...\n")
    print("--- INTERNAL THOUGHT PROCESS ---")

    stream = client.chat.completions.create(
        model=HETZNER_MODEL,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature=0.1,
        max_tokens=8192, # <--- BUMPED UP to allow for deep thinking
        stream=True
    )

    full_response = ""
    transitioned_to_content = False

    for chunk in stream:
        if chunk.choices:
            delta = chunk.choices[0].delta

            # 1. Check for Reasoning / Thinking Tokens
            # The OpenAI SDK might map this as an attribute or put it in model_extra
            reasoning_chunk = getattr(delta, 'reasoning', None)
            if reasoning_chunk is None and hasattr(delta, 'model_extra') and delta.model_extra:
                reasoning_chunk = delta.model_extra.get('reasoning')

            if reasoning_chunk:
                sys.stdout.write(reasoning_chunk)
                sys.stdout.flush()

            # 2. Check for the Actual Content Tokens
            if delta.content is not None:
                if not transitioned_to_content:
                    print("\n\n--- FINAL ANSWER ---")
                    transitioned_to_content = True

                sys.stdout.write(delta.content)
                sys.stdout.flush()
                full_response += delta.content

    return full_response

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ask.py \"How does tenant mailbox synchronization work?\"")
        sys.exit(1)

    query = " ".join(sys.argv[1:])
    print(f"🔍 Searching vector database for: '{query}'...")
    context = search_codebase(query)

    print(f"\n🤖 Hetzner ({HETZNER_MODEL}) is thinking...")

    response = ask_llm(query, context)

    print("\n" + "="*50)
    print(response)
    print("="*50)
