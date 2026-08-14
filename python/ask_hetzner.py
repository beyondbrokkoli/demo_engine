# ask_hetzner.py
import sys
from rag_qdrant import search_codebase
from rag_chat_hetzner import chat_loop_hetzner

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ask_hetzner.py \"How does tenant mailbox synchronization work?\"")
        sys.exit(1)

    initial_query = " ".join(sys.argv[1:])
    print(f"🔍 Initial search for: '{initial_query}'...")

    # Fetch initial context dump
    context = search_codebase(initial_query, limit=16)

    # Start interactive chat loop
    chat_loop_hetzner(initial_query, context)

    print("\n\n" + "="*50)
    print("SESSION TERMINATED")
    print("="*50)
