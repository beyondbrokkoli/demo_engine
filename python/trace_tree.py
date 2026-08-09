import os
import re
import fnmatch

def load_rules(filepath):
    """Parse .gitignore rules."""
    rules = []
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if line and not line.startswith('#'):
                    rules.append(line)
    return rules

def load_attributes(filepath):
    """Parse .gitattributes tags."""
    attrs = {}
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.split()
                    if len(parts) >= 2:
                        attrs[parts[0]] = parts[1:]
    return attrs

def is_ignored(rel_path, ignore_rules):
    """Check if a path matches any .gitignore rule."""
    if rel_path == '.git' or rel_path.startswith('.git/'):
        return True

    name = os.path.basename(rel_path)
    for rule in ignore_rules:
        rule_clean = rule.rstrip('/')
        # Match against just the filename (e.g. *.log) or the full relative path
        if fnmatch.fnmatch(name, rule_clean) or fnmatch.fnmatch(rel_path, rule_clean):
            return True
    return False

def get_special_class(rel_path, attributes):
    """Determine if a file is marked as generated or vendored in .gitattributes."""
    for pattern, tags in attributes.items():
        if fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(os.path.basename(rel_path), pattern):
            if any("linguist-generated=true" in tag or "linguist-vendored=true" in tag for tag in tags):
                return "special"
    return "file"

def generate_mermaid_tree():
    ignore_rules = load_rules(".gitignore")
    attributes = load_attributes(".gitattributes")

    nodes = []
    edges = []
    node_classes = {}

    # Initialize the root node
    root_name = os.path.basename(os.path.abspath("."))
    nodes.append(f'root["📁 {root_name}"]')
    node_classes["root"] = "dir"

    for dirpath, dirnames, filenames in os.walk("."):
        rel_dir = os.path.relpath(dirpath, ".").replace('\\', '/')
        if rel_dir == ".":
            rel_dir = ""

        # Filter directories in-place so os.walk ignores blacklisted folders entirely
        dirnames[:] = [
            d for d in dirnames
            if not is_ignored(os.path.join(rel_dir, d).replace('\\', '/').lstrip('/'), ignore_rules)
        ]

        # Process subdirectories
        for d in sorted(dirnames):
            full_path = os.path.join(rel_dir, d).replace('\\', '/').lstrip('/')
            parent_id = "root" if rel_dir == "" else "node_" + re.sub(r'[^a-zA-Z0-9]', '_', rel_dir)
            node_id = "node_" + re.sub(r'[^a-zA-Z0-9]', '_', full_path)

            nodes.append(f'{node_id}["📁 {d}"]')
            edges.append(f'{parent_id} --> {node_id}')
            node_classes[node_id] = "dir"

        # Process files
        for f in sorted(filenames):
            full_path = os.path.join(rel_dir, f).replace('\\', '/').lstrip('/')
            if is_ignored(full_path, ignore_rules):
                continue

            parent_id = "root" if rel_dir == "" else "node_" + re.sub(r'[^a-zA-Z0-9]', '_', rel_dir)
            node_id = "node_" + re.sub(r'[^a-zA-Z0-9]', '_', full_path)

            cls = get_special_class(full_path, attributes)
            nodes.append(f'{node_id}["📄 {f}"]')
            edges.append(f'{parent_id} --> {node_id}')
            node_classes[node_id] = cls

    # Assemble the Mermaid payload with ELK constraints and CSS class definitions
    lines = [
        "```mermaid",
        '%%{init: {"flowchart": {"defaultRenderer": "elk", "nodeSpacing": 15, "rankSpacing": 45}}}%%',
        "flowchart LR",
        "    %% Directory Styling (Blue, Rounded)",
        "    classDef dir fill:#1e293b,stroke:#3b82f6,stroke-width:2px,color:#f8fafc,rx:6,ry:6",
        "    %% Standard File Styling (Green)",
        "    classDef file fill:#0f172a,stroke:#10b981,stroke-width:1px,color:#cbd5e1",
        "    %% Vendored/Generated File Styling (Amber, Dashed)",
        "    classDef special fill:#0f172a,stroke:#f59e0b,stroke-width:1px,stroke-dasharray: 4 4,color:#94a3b8",
        ""
    ]

    lines.extend(["    " + n for n in nodes])
    lines.append("")
    lines.extend(["    " + e for e in edges])
    lines.append("")

    for nid, cls in node_classes.items():
        lines.append(f"    class {nid} {cls}")

    lines.append("```\n")
    return "\n".join(lines)

if __name__ == "__main__":
    mmd_output = generate_mermaid_tree()
    os.makedirs("docs", exist_ok=True)
    out_file = "docs/repo_tree.md"

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(mmd_output)

    print(f"Generated {out_file} successfully.")
