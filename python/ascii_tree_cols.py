import os
import fnmatch
import math

def load_rules(filepath):
    """Parse .gitignore rules."""
    if not os.path.exists(filepath):
        return []
    with open(filepath, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip() and not line.startswith('#')]

def is_ignored(rel_path, rules):
    """Check if a path matches any .gitignore rule."""
    if rel_path == '.git' or rel_path.startswith('.git/'):
        return True

    name = os.path.basename(rel_path)
    for rule in rules:
        rule_clean = rule.rstrip('/')
        if fnmatch.fnmatch(name, rule_clean) or fnmatch.fnmatch(rel_path, rule_clean):
            return True
    return False

def build_tree(dir_path, rules, prefix=""):
    """Recursively build the ASCII tree lines."""
    lines = []
    try:
        items = sorted(os.listdir(dir_path))
    except PermissionError:
        return lines

    # Filter ignored items
    items = [i for i in items if not is_ignored(os.path.relpath(os.path.join(dir_path, i), "."), rules)]

    for i, item in enumerate(items):
        is_last = (i == len(items) - 1)
        connector = "└── " if is_last else "├── "
        is_dir = os.path.isdir(os.path.join(dir_path, item))

        display_name = f"{item}/" if is_dir else item
        lines.append(f"{prefix}{connector}{display_name}")

        if is_dir:
            extension = "    " if is_last else "│   "
            lines.extend(build_tree(os.path.join(dir_path, item), rules, prefix + extension))

    return lines

def columnize(lines, num_columns=2, column_width=8):
    """Wrap a 1D array of lines into dense horizontal columns."""
    # Pad strings with spaces to ensure columns align perfectly
    padded = [line.ljust(column_width)[:column_width] for line in lines]

    # Calculate how many rows are needed per column
    rows = math.ceil(len(padded) / num_columns)

    output = []
    for r in range(rows):
        row_str = ""
        for c in range(num_columns):
            idx = c * rows + r
            if idx < len(padded):
                row_str += padded[idx]
        output.append(row_str)

    return output

if __name__ == "__main__":
    rules = load_rules(".gitignore")
    root_name = os.path.basename(os.path.abspath("."))

    # Generate flat vertical tree
    tree_lines = [f"{root_name}/"] + build_tree(".", rules)

    # Force 2 columns. Width 43 * 2 = 86 chars (Fits standard GitHub Markdown width)
    col_lines = columnize(tree_lines, num_columns=2, column_width=43)

    final_output = "\n".join(col_lines)

    # Print to terminal
    print(final_output)

    # Optionally save to a raw text file for your README
    os.makedirs("docs", exist_ok=True)
    with open("docs/repo_ascii.txt", "w", encoding="utf-8") as f:
        f.write(final_output)
