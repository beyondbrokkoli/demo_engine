import os
import re
from collections import defaultdict

ROOT_LUA_FILES = []
LUA_DIRS = ["build", "ssot", "runtime", "network", "worlds", "tools"]
REQUIRE_PATTERN = re.compile(r"require\s*(?:\(\s*['\"]([^'\"]+)['\"]\s*\)|['\"]([^'\"]+)['\"])")

# Blacklist to strip ubiquitous utilities and reduce graph clutter
BLACKLIST = {"dkjson", "ffi", "math", "bit", "debug", "lpeg"}

def sanitize_id(filepath):
    return re.sub(r'[^a-zA-Z0-9_]', '_', filepath)

def scan_dependencies():
    file_map = {}

    def index_file(filepath):
        rel_path = os.path.relpath(filepath).replace("\\", "/")
        base = os.path.splitext(os.path.basename(rel_path))[0]
        file_map[base] = rel_path
        dot_path = os.path.splitext(rel_path)[0].replace("/", ".")
        file_map[dot_path] = rel_path

    for root_file in ROOT_LUA_FILES:
        if os.path.exists(root_file):
            index_file(root_file)

    for d in LUA_DIRS:
        if not os.path.exists(d): continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith(".lua"):
                    index_file(os.path.join(root, file))

    graph = defaultdict(list)

    def parse_file(filepath):
        rel_path = os.path.relpath(filepath).replace("\\", "/")
        if rel_path not in graph:
            graph[rel_path] = []

        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                if line.lstrip().startswith("--"): continue
                for match in REQUIRE_PATTERN.findall(line):
                    req = match[0] if match[0] else match[1]
                    resolved_path = file_map.get(req, req)

                    # Extract just the file/module name to safely check against the blacklist
                    module_name = os.path.basename(resolved_path).replace(".lua", "")

                    # 1. Skip if explicitly blacklisted
                    if req in BLACKLIST or module_name in BLACKLIST:
                        continue

                    # 2. Skip anything that doesn't have a path separator to permanently drop the 'external' block
                    if '/' not in resolved_path:
                        continue

                    graph[rel_path].append(resolved_path)

    for root_file in ROOT_LUA_FILES:
        if os.path.exists(root_file):
            parse_file(root_file)

    for d in LUA_DIRS:
        if not os.path.exists(d): continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith(".lua"):
                    parse_file(os.path.join(root, file))

    return graph

def generate_mermaid(graph):
    all_nodes = set(graph.keys())
    for edges in graph.values():
        all_nodes.update(edges)

    groups = defaultdict(list)
    for node in all_nodes:
        # Externals are already filtered out, so everything here will have a '/'
        group = node.split('/')[0] if '/' in node else 'external'
        groups[group].append(node)

    # Inject ELK layout renderer and horizontal flow
    lines = [
        "```mermaid",
        '%%{init: {"flowchart": {"defaultRenderer": "elk"}}}%%',
        "flowchart LR",
        "    %% WeaverEngine Lua Dependencies"
    ]

    for group, nodes in sorted(groups.items()):
        if group == 'external': continue # Extra safety net
        lines.append(f"    subgraph {group}")
        for node in sorted(nodes):
            lines.append(f'        {sanitize_id(node)}["{node}"]')
        lines.append("    end")

    for src in sorted(graph.keys()):
        src_id = sanitize_id(src)
        for dst in sorted(set(graph[src])):
            dst_id = sanitize_id(dst)
            lines.append(f"    {src_id} --> {dst_id}")

    lines.append("```\n")
    return "\n".join(lines)

if __name__ == "__main__":
    deps = scan_dependencies()
    mmd_output = generate_mermaid(deps)

    os.makedirs("docs", exist_ok=True)
    out_file = "docs/deps_lua.md"
    with open(out_file, "w") as f:
        f.write(mmd_output)
    print(f"Generated {out_file}")
