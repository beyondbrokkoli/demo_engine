# rag_chat.py
import sys
from openai import OpenAI
from rag_config import LOCAL_LLM_URL, LOCAL_LLM_API_KEY, LOCAL_MODEL
from rag_qdrant import search_codebase

def chat_loop(initial_query, initial_context):
    system_prompt = (
        "Answer the user's question using ONLY the provided code context. "
        "Do not use outside knowledge. "
        "Cite the exact file name in brackets for every claim you make."
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"RETRIEVED CODE CONTEXT:\n{initial_context}\n\nUSER QUESTION:\n{initial_query}"}
    ]

    client = OpenAI(base_url=LOCAL_LLM_URL, api_key=LOCAL_LLM_API_KEY)

    while True:
        print(f"\n🤖 Qwen 2.5 Coder is thinking...\n")

        stream = client.chat.completions.create(
            model=LOCAL_MODEL,
            messages=messages,
            temperature=0.1,
            max_tokens=8192, # Ensure max_tokens accommodates your context size
            stream=True
        )

        full_response = ""
        for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content is not None:
                sys.stdout.write(chunk.choices[0].delta.content)
                sys.stdout.flush()
                full_response += chunk.choices[0].delta.content

        messages.append({"role": "assistant", "content": full_response})

        print("\n\n" + "="*50)
        next_query = input("Ask a follow-up (or type 'exit'): ")

        if next_query.lower() in ['exit', 'quit']:
            break

        # --- MID-CONVERSATION RAG TRIGGER ---
        print(f"\n🔍 Fetching fresh codebase context for: '{next_query}'...")
        # Lower limit for follow-ups to avoid blowing out the context window
        new_context = search_codebase(next_query, limit=3)

        # Inject the new code directly alongside the new question
        enriched_query = (
            f"NEWLY RETRIEVED CONTEXT (Use if relevant):\n{new_context}\n\n"
            f"FOLLOW-UP QUESTION:\n{next_query}"
        )

        messages.append({"role": "user", "content": enriched_query})
