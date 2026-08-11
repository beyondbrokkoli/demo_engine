import os
import sys
import uuid
import re
import requests
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# --- Configuration ---
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "weaver_dev_nomic"
GEMINI_DIMENSIONS = 768 # Matches Nomic natively

LOCAL_EMBED_URL = "http://127.0.0.1:8081/v1/embeddings"
LOCAL_API_KEY = "TEST1234"

DOT_FILE_LUA = "docs/deps_lua.md"
DOT_FILE_C = "docs/deps_c.md"
DOT_FILE_GLSL = "docs/deps_glsl.md"

# --- THE ABSOLUTE SOURCE OF TRUTH ---
INGESTION_MANIFEST = [
    # Top-level Lua
#    "cli_sys.lua",
#    "launch.lua",

    # Build System
    "build/build.lua",
    "build/check_build_dependencies.lua",
    "build/export_c_hdr.lua",
    "build/export_glsl.lua",
    "build/task_c_objects.lua",
    "build/task_headless.lua",
    "build/task_invariants.lua",
    "build/task_shaders.lua",

    # SSOT & Generated Headers / Shaders
    "generated/registry.glsl",
    "generated/ssot_render.h",
    "generated/ssot_types.h",
    "ssot/config_gfx.lua",
    "ssot/config_sim.lua",
    "ssot/ctx_types.lua",
    "ssot/registry.glsl",
    "ssot/type_math.lua",
    "ssot/type_render.lua",

    # Host Engine Core (C)
    "host/boot/lifecycle.c",
    "host/boot/main.c",
    "host/boot/main_headless.c",
    "host/ipc/mailbox.c",
    "host/ipc/ring_stream.c",
    "host/ipc/sys_sync.c",
    "host/lua/lua_vm.c",
    "host/runtime/main_loop.c",
    "host/state/state_globals.c",
    "host/state/state_types.c",
    "host/tenant/tenant_callbacks.c",
    "host/tenant/tenant_callbacks_key.c",
    "host/tenant/tenant_callbacks_mouse.c",
    "host/tenant/tenant_callbacks_state.c",
    "host/tenant/tenant_input.c",
    "host/tenant/tenant_sys.c",
    "host/threading/thread_lifecycle.c",
    "host/threading/thread_pool.c",

    # Networking Core (C & Lua)
    # "network/lockstep/fsm_core.lua",
    # "network/lockstep/fsm_pacing.lua",
    # "network/lockstep/fsm_simulator.lua",
    # "network/lockstep/history_buffer.lua",
    # "network/lockstep/wire_codec.lua",
    # "network/protocol/config_net.lua",
    # "network/protocol/dkjson.lua",
    # "network/protocol/json_util.lua",
    # "network/protocol/shared_structs.h",
    # "network/protocol/structs.lua",
    # "network/session/netcode.lua",
    # "network/session/net_utils.lua",
    # "network/transport/net_pump.lua",
    # "network/transport/network.lua",
    # "network/transport/vx_net.c",

    # Vulkan Render Engine (C)
    "render/debug/vk_debug.c",
    "render/gpu/vk_draw.c",
    "render/gpu/vk_record.c",
    "render/gpu/vk_render_loop.c",
    "render/tenant/vk_tenant_alloc.c",
    "render/transfer/vk_transfer_api.c",
    "render/transfer/vk_transfer_loop.c",

    # Shaders
    "shaders/render.frag",
    "shaders/render.vert",
    "shaders/shared.glsl",

    # Runtime Engine Systems (Lua)
    # "runtime/boot/core_abi.lua",
    # "runtime/boot/engine_api.lua",
    # "runtime/boot/main.lua",
    # "runtime/boot/path_weaver.lua",
    # "runtime/boot/weaver_boot.lua",
    # "runtime/boot/window_api.lua",
    # "runtime/presentation/graphics/compute_pipeline.lua",
    # "runtime/presentation/graphics/graphics_pipeline.lua",
    # "runtime/presentation/graphics/renderer.lua",
    # "runtime/presentation/graphics/sequence.lua",
    # "runtime/presentation/translation/pipeline_manifest.lua",
    # "runtime/presentation/translation/render_queue.lua",
    # "runtime/services/gpu/descriptors.lua",
    # "runtime/services/gpu/registry_vk.lua",
    # "runtime/services/gpu/swapchain.lua",
    # "runtime/services/gpu/vulkan_core.lua",
    # "runtime/services/gpu/vulkan_headers.lua",
    # "runtime/services/gpu/weaver_vram.lua",
    # "runtime/services/math/fixed_math.lua",
    # "runtime/services/math/vmath.lua",
    # "runtime/services/memory/memory.lua",
    # "runtime/services/tenants/tenant_lifecycle.lua",
    # "runtime/services/tenants/tenant_registry.lua",
    # "runtime/shutdown/teardown.lua",
    # "runtime/simulation/camera.lua",
    # "runtime/simulation/game_state.lua",
    # "runtime/simulation/raycast.lua",

    # Tools & Game Domains
    # "tools/bot.lua",
    # "worlds/chess/domain.lua",
    # "worlds/isometric/domain.lua",
    # "worlds/luachess/game/attack.lua",
    # "worlds/luachess/game/logic.lua",
    # "worlds/luachess/game/move.lua",
    # "worlds/luachess/game/standard.lua",
    # "worlds/luachess/game/turn.lua",
    # "worlds/luachess/global.lua",
    # "worlds/router_plugin.lua",
]


def parse_dependencies(dot_filepath):
    deps_map = {}
    if not os.path.exists(dot_filepath):
        print(f"[-] Dependency graph '{dot_filepath}' not found. Skipping topology injection.")
        return deps_map

    with open(dot_filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    edges = re.findall(r'"([^"]+)"\s*->\s*"([^"]+)"', content)
    for source, target in edges:
        if source not in deps_map:
            deps_map[source] = []
        deps_map[source].append(target)

    return deps_map

def validate_lua_invariants(module_name, source_code, expected_deps_from_dot):
    matches = re.findall(r'require\s*\(\s*["\']([^"\']+)["\']\s*\)|require\s+["\']([^"\']+)["\']', source_code)

    actual_requires = set()
    for match in matches:
        req = match[0] if match[0] else match[1]
        if req not in ["ffi", "math", "bit", "os", "io", "string"]:
            actual_requires.add(req)

    expected_requires = set(expected_deps_from_dot)
    expected_requires = {dep for dep in expected_requires if dep not in ["ffi", "math", "bit"]}

    if actual_requires != expected_requires:
        print(f"\n[FATAL INVARIANT] Architecture drift detected in '{module_name}.lua'")
        print(f" |- Expected (deps_lua.dot): {expected_requires}")
        print(f" |- Actual (Lua source):  {actual_requires}")
        sys.exit(1)

def validate_include_invariants(file_name, source_code, expected_deps_from_dot, domain="C"):
    matches = re.findall(r'#include\s+"([^"]+)"', source_code)

    actual_requires = set()
    for match in matches:
        actual_requires.add(os.path.basename(match))

    expected_requires = set(expected_deps_from_dot)

    if actual_requires != expected_requires:
        print(f"\n[FATAL INVARIANT] {domain} Architecture drift detected in '{file_name}'")
        print(f" |- Expected (deps_{domain.lower()}.dot): {expected_requires}")
        print(f" |- Actual ({domain} source):     {actual_requires}")
        sys.exit(1)

def get_embedding(text):
    headers = {
        "Authorization": f"Bearer {LOCAL_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {"input": text}
    response = requests.post(LOCAL_EMBED_URL, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()['data'][0]['embedding']

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
    topology_lua = parse_dependencies(DOT_FILE_LUA)
    topology_c = parse_dependencies(DOT_FILE_C)
    topology_glsl = parse_dependencies(DOT_FILE_GLSL)
    points = []

    print(f"Validating and vectorizing {len(INGESTION_MANIFEST)} manifested files...\n")

    for filepath in INGESTION_MANIFEST:
        if not os.path.exists(filepath):
            print(f" [WARNING] File missing from disk: {filepath}")
            continue

        filename = os.path.basename(filepath)
        module_name = os.path.splitext(filename)[0]
        ext = os.path.splitext(filename)[1].lower()

        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            source_code = f.read().strip()

        if not source_code:
            continue

        # --- INVARIANT ASSERTION & DEPENDENCY RESOLUTION ---
        if ext == ".lua":
            dependencies = topology_lua.get(module_name, [])
            validate_lua_invariants(module_name, source_code, dependencies)
        elif ext in [".c", ".h"]:
            dependencies = topology_c.get(filename, [])
            validate_include_invariants(filename, source_code, dependencies, domain="C")
        elif ext in [".glsl", ".frag", ".vert"]:
            dependencies = topology_glsl.get(filename, [])
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
        points.append(PointStruct(
            id=point_id,
            vector=vector,
            payload={
                "file": filepath,
                "dependencies": dependencies,
                "content": source_code,
                "full_context": contextual_payload
            }
        ))

    if points:
        print(f"\nUpserting {len(points)} modules into Qdrant...")
        qdrant.upsert(
            collection_name=COLLECTION_NAME,
            points=points
        )
        print("Codebase successfully indexed and mapped!")
    else:
        print("No valid files found to index.")

if __name__ == "__main__":
    main()
