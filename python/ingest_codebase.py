# ingest_codebase.py
import os
import uuid
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# --- Local Module Imports ---
from ingest_config import (
    QDRANT_URL, COLLECTION_NAME, GEMINI_DIMENSIONS,
    DOC_FILE_LUA, DOC_FILE_C, DOC_FILE_GLSL
)
from ingestion_manifest import INGESTION_MANIFEST
from ingest_topology import parse_dependencies
from ingest_validators import validate_lua_invariants, validate_include_invariants
from ingest_embeddings import get_embedding

def main():
    print(f"\n=== LOCAL NOMIC EMBEDDING RUN ({COLLECTION_NAME}) ===")
    print("Connecting to Qdrant...")
    qdrant = QdrantClient(url=QDRANT_URL)

    if qdrant.collection_exists(collection_name=COLLECTION_NAME):
        print(f" [!] Purging existing '{COLLECTION_NAME}'...")
        qdrant.delete_collection(collection_name=COLLECTION_NAME)

    print(f" [*] Creating fresh Qdrant collection '{COLLECTION_NAME}'...")
    qdrant.create_collection(
        collection_name=COLLECTION_NAME,
        vectors_config=VectorParams(size=GEMINI_DIMENSIONS, distance=Distance.COSINE),
    )

    print("Parsing architecture topologies...")
    topology_lua = parse_dependencies(DOC_FILE_LUA, domain="LUA")
    topology_c = parse_dependencies(DOC_FILE_C, domain="C")
    topology_glsl = parse_dependencies(DOC_FILE_GLSL, domain="GLSL")
    points = []

    print(f"Validating and vectorizing {len(INGESTION_MANIFEST)} manifested files...\n")

    for filepath in INGESTION_MANIFEST:
        if not os.path.exists(filepath):
            print(f" [WARNING] File missing from disk: {filepath}")
            continue

        filename = os.path.basename(filepath)
        module_name = os.path.splitext(filename)[0]
        ext = os.path.splitext(filename)[1].lower()

        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            source_code = f.read().strip()

        if not source_code:
            continue

        # --- INVARIANT ASSERTION & DEPENDENCY RESOLUTION ---
        if ext == ".lua":
            dependencies = topology_lua.get(filepath, topology_lua.get(module_name, []))
            validate_lua_invariants(filepath, source_code, dependencies)
        elif ext in [".c", ".h"]:
            dependencies = topology_c.get(filepath, topology_c.get(filename, []))
            validate_include_invariants(filename, source_code, dependencies, domain="C")
        elif ext in [".glsl", ".frag", ".vert"]:
            dependencies = topology_glsl.get(filepath, topology_glsl.get(filename, []))
            validate_include_invariants(filename, source_code, dependencies, domain="GLSL")
        else:
            dependencies = []

        dep_string = ", ".join(dependencies) if dependencies else "None (Level 0 / Root)"
        contextual_payload = (
            f"MODULE: {filepath}\n"
            f"DEPENDENCIES: {dep_string}\n"
            f"SOURCE CODE:\n{source_code}"
        )

        print(f" [OK] Vectorizing Module: {filepath} (Deps: {len(dependencies)})")
        vector = get_embedding(contextual_payload)

        point_id = str(uuid.uuid5(uuid.NAMESPACE_URL, filepath))
        points.append(
            PointStruct(
                id=point_id,
                vector=vector,
                payload={
                    "file": filepath,
                    "dependencies": dependencies,
                    "content": source_code,
                    "full_context": contextual_payload,
                },
            )
        )

    if points:
        print(f"\nUpserting {len(points)} modules into Qdrant...")
        qdrant.upsert(collection_name=COLLECTION_NAME, points=points)
        print("Codebase successfully indexed and mapped!")
    else:
        print("No valid files found to index.")

if __name__ == "__main__":
    main()
