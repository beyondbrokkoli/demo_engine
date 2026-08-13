# rag_config.py
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"

# Local Embeddings (Nomic via llama-server)
LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_EMBED_API_KEY = "TEST1234"

# Local LLM Configuration (Qwen 2.5 Coder)
LOCAL_LLM_URL = "http://127.0.0.1:8080/v1"
LOCAL_LLM_API_KEY = "TEST1234"
LOCAL_MODEL = "Qwen2.5-Coder-32B-Instruct"
