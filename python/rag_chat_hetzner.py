# rag_config.py
import os

# --- Vector Store & Embeddings ---
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"

# Local Embeddings (Nomic via llama-server - used by both pipelines)
LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_EMBED_API_KEY = "TEST1234"

# --- Local LLM Configuration (Qwen 2.5 Coder) ---
LOCAL_LLM_URL = "http://127.0.0.1:8080/v1"
LOCAL_LLM_API_KEY = "TEST1234"
LOCAL_MODEL = "Qwen2.5-Coder-32B-Instruct"

# --- Hetzner API Configuration ---
HETZNER_BASE_URL = "https://inference.hetzner.com/api/v1"
HETZNER_API_KEY = os.getenv("HETZNER_API_KEY", "")

# Options: "Kimi-K2.7-Code", "Qwen/Qwen3.6-35B-A3B-FP8", "DeepSeek-V4-Flash-0731"
HETZNER_MODEL = "Qwen/Qwen3.6-35B-A3B-FP8"
