# ask_local.py
import sys
from rag_qdrant import search_codebase
from rag_chat import chat_loop

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ask_local.py \"How does tenant mailbox synchronization work?\"")
        sys.exit(1)

    initial_query = " ".join(sys.argv[1:])
    print(f"🔍 Initial search for: '{initial_query}'...")

    # Bumped the limit up to 15 files to take advantage of Qwen's large context
    context = search_codebase(initial_query, limit=15)

    # Kick off the persistent chat
    chat_loop(initial_query, context)

    print("\n\n" + "="*50)
    print("SESSION TERMINATED")
    print("="*50)
