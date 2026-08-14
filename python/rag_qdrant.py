# rag_qdrant.py
import re
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue
from rag_config import QDRANT_URL, COLLECTION_NAME
from rag_embeddings import get_query_vector

qdrant = QdrantClient(url=QDRANT_URL)

def extract_filenames(query):
    """Regex to find Weaver Engine files (e.g., sys_sync.h, engine.lua, main.c)"""
    # Matches words ending in your project's specific extensions
    pattern = r'\b[\w/-]+\.(?:c|h|lua|py|glsl|frag|vert|md)\b'
    return re.findall(pattern, query)

def search_codebase(query, limit=16):
    """Queries Qdrant for relevant modules and formats dependency metadata."""
    query_vector = get_query_vector(query)

    # --- AUTO-FILENAME DETECTION ---
    mentioned_files = extract_filenames(query)
    qdrant_filter = None

    if mentioned_files:
        print(f"🎯 [FILTER] Detected specific files in query: {mentioned_files}")
        # Build an OR filter (should) for any mentioned file
        # Note: MatchValue requires exact payload match (e.g., 'src/main.c')
        qdrant_filter = Filter(
            should=[
                FieldCondition(key="file", match=MatchValue(value=f))
                for f in mentioned_files
            ]
        )

    results = qdrant.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        query_filter=qdrant_filter,
        limit=limit
    )

    contexts = []
    print(f"\n📚 [RETRIEVAL] Qdrant pulled {len(results.points)} modules:")
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
