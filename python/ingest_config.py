# ingest_config.py
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"
GEMINI_DIMENSIONS = 768  # Matches Nomic natively

# Local Embeddings (Nomic via llama-server)
LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_API_KEY = "TEST1234"

# Dependency Documentation Files (Markdown/Mermaid)
DOC_FILE_LUA = "docs/deps_lua.md"
DOC_FILE_C = "docs/deps_c.md"
DOC_FILE_GLSL = "docs/deps_glsl.md"
