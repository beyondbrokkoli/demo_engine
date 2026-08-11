import os
import sys
from openai import OpenAI

# 1. Grab the API key from your environment
api_key = os.getenv("HETZNER_API_KEY")
if not api_key:
    print("Error: HETZNER_API_KEY environment variable is not set.")
    sys.exit(1)

# 2. Initialize the OpenAI client pointing to Hetzner
client = OpenAI(
    base_url="https://inference.hetzner.com/api/v1",
    api_key=api_key,
)

MODEL = "Qwen/Qwen3.6-35B-A3B-FP8"

print(f"📡 Connecting to Hetzner API (Model: {MODEL})...\n")

try:
    # 3. Send the prompt with streaming DISABLED
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful AI assistant."},
            {"role": "user", "content": "Hello! Please write a very short haiku about compiling C code."}
        ],
        temperature=0.3,
        max_tokens=100,
        stream=False  # <--- Turned off streaming
    )

    # 4. Dump the raw response object to the terminal
    print("✅ Request completed! Here is the raw API dump:\n")
    print("=" * 50)

    # model_dump_json() prints the entire response as formatted JSON
    print(response.model_dump_json(indent=2))

    print("=" * 50)

except Exception as e:
    print(f"\n❌ Error connecting to Hetzner: {e}")
