# rag_chat_hetzner.py
import sys
import os
from openai import OpenAI
from rag_config import HETZNER_BASE_URL, HETZNER_API_KEY, HETZNER_MODEL
from rag_qdrant import search_codebase

def chat_loop_hetzner(initial_query, initial_context):
    if not HETZNER_API_KEY:
        print("❌ Error: HETZNER_API_KEY environment variable is not set.")
        sys.exit(1)

    # --- INJECT SKILL.MD ---
    skill_content = ""
    try:
        with open("skill.md", "r", encoding="utf-8") as f:
            skill_content = f.read()
            print("✅ Successfully loaded and injected skill.md into system prompt.")
    except FileNotFoundError:
        print("⚠️ Warning: skill.md not found in the current directory. Proceeding without it.")

    system_prompt = (
        "Answer the user's question using ONLY the provided code context. "
        "Do not use outside knowledge. "
        "Cite the exact file name in brackets for every claim you make.\n\n"
        "--- ADDITIONAL DEVELOPER INSTRUCTIONS (skill.md) ---\n"
        f"{skill_content}\n"
        "----------------------------------------------------"
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"RETRIEVED CODE CONTEXT:\n{initial_context}\n\nUSER QUESTION:\n{initial_query}"}
    ]

    client = OpenAI(base_url=HETZNER_BASE_URL, api_key=HETZNER_API_KEY)

    while True:
        print(f"\n🤖 Hetzner ({HETZNER_MODEL}) is thinking...\n")

        stream = client.chat.completions.create(
            model=HETZNER_MODEL,
            messages=messages,
            temperature=0.1,
            max_tokens=8192,
            stream=True
        )

        full_response = ""
        in_thinking = False
        transitioned_to_content = False

        for chunk in stream:
            if not chunk.choices:
                continue

            delta = chunk.choices[0].delta

            # 1. Parse Reasoning / Thinking Scratchpad Tokens
            reasoning_chunk = getattr(delta, 'reasoning', None)
            if reasoning_chunk is None and hasattr(delta, 'model_extra') and delta.model_extra:
                reasoning_chunk = delta.model_extra.get('reasoning')

            if reasoning_chunk:
                if not in_thinking:
                    print("--- INTERNAL THOUGHT PROCESS ---")
                    in_thinking = True
                sys.stdout.write(reasoning_chunk)
                sys.stdout.flush()

            # 2. Parse Final Answer Content
            if delta.content is not None:
                if not transitioned_to_content:
                    if in_thinking:
                        print("\n\n--- FINAL ANSWER ---")
                    transitioned_to_content = True
                sys.stdout.write(delta.content)
                sys.stdout.flush()
                full_response += delta.content

        messages.append({"role": "assistant", "content": full_response})

        print("\n\n" + "="*50)
        next_query = input("Ask a follow-up (or type 'exit'): ")

        if next_query.lower() in ['exit', 'quit']:
            break

        # --- MID-CONVERSATION RAG TRIGGER ---
        print(f"\n🔍 Fetching fresh codebase context for: '{next_query}'...")
        new_context = search_codebase(next_query, limit=3)

        enriched_query = (
            f"NEWLY RETRIEVED CONTEXT (Use if relevant):\n{new_context}\n\n"
            f"FOLLOW-UP QUESTION:\n{next_query}"
        )

        messages.append({"role": "user", "content": enriched_query})
