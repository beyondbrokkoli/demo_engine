import os
import sys
import requests
from qdrant_client import QdrantClient
from openai import OpenAI

# --- Configuration ---
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"

# Local Embeddings (Nomic)
LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_EMBED_API_KEY = "TEST1234"

# --- Local LLM Configuration (Qwen 2.5 Coder) ---
LOCAL_LLM_URL = "http://127.0.0.1:8080/v1"
LOCAL_LLM_API_KEY = "TEST1234"
LOCAL_MODEL = "Qwen2.5-Coder-32B-Instruct"

qdrant = QdrantClient(url=QDRANT_URL)

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

def search_codebase(query, limit=15):
    """Queries Qdrant for relevant modules and formats dependency metadata."""
    query_vector = get_query_vector(query)
    results = qdrant.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        limit=limit
    )

    contexts = []
    print(f"\n📚 [RETRIEVAL] Qdrant pulled the top {limit} modules:")
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
    """Sends the retrieved context and question to the local llama.cpp server."""

    # REFINED PROMPT: Highly compressed and tailored to the Weaver Engine's specific architecture
    system_prompt = (
        "You are the Lead Systems Architect for the Weaver Engine, a custom hybrid C/Lua game engine. "
        "The architecture features a low-overhead C-based Host (handling Vulkan rendering, threading, and IPC mailboxes) "
        "driving a Lua-based Tenant/Runtime simulation built on deterministic lockstep networking, state rollback, "
        "and fixed-point math.\n\n"
        "Your task is to answer the user's architectural query with absolute precision using ONLY the provided RAG context.\n\n"
        "CRITICAL DIRECTIVES:\n"
        "1. ZERO HALLUCINATION: Base your entire response ONLY on the provided C/Lua/GLSL snippets. "
        "Do not invent functions, structs, or logic that are not explicitly written in the context.\n"
        "2. CROSS-BOUNDARY AWARENESS: Pay strict attention to how data crosses the C/Lua FFI boundary, "
        "how memory is managed between them, and how tenant state is synchronized.\n"
        "3. EXPLICIT CITATION: Every technical claim, data flow step, or logic explanation MUST "
        "cite the exact source file in brackets, e.g., `[host/ipc/mailbox.c]` or `[network/lockstep/history_buffer.lua]`.\n\n"
        "EXECUTION FORMAT:\n"
        "Always begin with a <scratchpad> block to briefly map out the relevant files and trace the data flow. "
        "Once your mapping is complete, close the block and output the FINAL ANALYSIS."
    )

    user_prompt = f"RETRIEVED CODE CONTEXT:\n{context}\n\nUSER QUESTION:\n{query}"

    client = OpenAI(
        base_url=LOCAL_LLM_URL,
        api_key=LOCAL_LLM_API_KEY,
    )

    print(f"\n🤖 Qwen 2.5 Coder is thinking...\n")

    stream = client.chat.completions.create(
        model=LOCAL_MODEL,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature=0.1,
        max_tokens=8192, 
        stream=True
    )

    full_response = ""
    for chunk in stream:
        if chunk.choices:
            delta = chunk.choices[0].delta
            if delta.content is not None:
                sys.stdout.write(delta.content)
                sys.stdout.flush()
                full_response += delta.content

    return full_response

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ask_local.py \"How does tenant mailbox synchronization work?\"")
        sys.exit(1)

    query = " ".join(sys.argv[1:])
    print(f"🔍 Searching vector database for: '{query}'...")

    # Bumped the limit up to 15 files to take advantage of Qwen's large context
    context = search_codebase(query, limit=15)

    response = ask_llm(query, context)

    print("\n\n" + "="*50)
    print("FINISHED")
    print("="*50)
