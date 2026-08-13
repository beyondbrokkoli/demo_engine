# ingest_topology.py
import os
import re

def parse_dependencies(filepath, domain="LUA"):
    """Parses dependency topology from Mermaid (.md) or Graphviz (.dot) files."""
    deps_map = {}

    # Auto-resolve .md / .dot extension fallbacks
    if not os.path.exists(filepath):
        base, _ = os.path.splitext(filepath)
        if os.path.exists(base + ".md"):
            filepath = base + ".md"
        elif os.path.exists(base + ".dot"):
            filepath = base + ".dot"
        else:
            print(f"[-] Dependency graph '{filepath}' not found. Skipping topology injection.")
            return deps_map

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    ext = os.path.splitext(filepath)[1].lower()

    if ext == ".md":
        # 1. Parse Mermaid Node Definitions: node_id["label"]
        nodes = {}
        node_matches = re.findall(r'([a-zA-Z0-9_]+)\["([^"]+)"\]', content)
        for node_id, label in node_matches:
            nodes[node_id] = label

        # 2. Parse Mermaid Edges: src_id --> tgt_id
        edge_matches = re.findall(r'([a-zA-Z0-9_]+)\s*(?:-->|-.->)\s*([a-zA-Z0-9_]+)', content)
        for src_id, tgt_id in edge_matches:
            src_label = nodes.get(src_id)
            tgt_label = nodes.get(tgt_id)
            if not src_label or not tgt_label:
                continue

            if domain == "LUA":
                # Convert path to Lua module require notation: "build/export_c_hdr.lua" -> "build.export_c_hdr"
                src_mod = src_label.removesuffix(".lua").replace("/", ".")
                tgt_mod = tgt_label.removesuffix(".lua").replace("/", ".")

                # Populate multiple key variants for robust lookup
                src_keys = {
                    src_label,
                    src_mod,
                    os.path.basename(src_label),
                    os.path.splitext(os.path.basename(src_label))[0],
                }
                for key in src_keys:
                    if key not in deps_map:
                        deps_map[key] = []
                    if tgt_mod not in deps_map[key]:
                        deps_map[key].append(tgt_mod)
            else:
                # C / GLSL domain: match basenames e.g. "sys_sync.h"
                src_name = os.path.basename(src_label)
                tgt_name = os.path.basename(tgt_label)

                src_keys = {src_label, src_name, os.path.splitext(src_name)[0]}
                for key in src_keys:
                    if key not in deps_map:
                        deps_map[key] = []
                    if tgt_name not in deps_map[key]:
                        deps_map[key].append(tgt_name)

    elif ext == ".dot":
        # Graphviz DOT parser
        edges = re.findall(r'"([^"]+)"\s*->\s*"([^"]+)"', content)
        for source, target in edges:
            src_keys = {
                source,
                os.path.basename(source),
                os.path.splitext(os.path.basename(source))[0],
            }
            if domain == "LUA":
                target_mod = target.removesuffix(".lua").replace("/", ".")
                src_keys.add(source.removesuffix(".lua").replace("/", "."))
                for key in src_keys:
                    if key not in deps_map:
                        deps_map[key] = []
                    if target_mod not in deps_map[key]:
                        deps_map[key].append(target_mod)
            else:
                target_name = os.path.basename(target)
                for key in src_keys:
                    if key not in deps_map:
                        deps_map[key] = []
                    if target_name not in deps_map[key]:
                        deps_map[key].append(target_name)

    return deps_map
