import os
import sys
from collections import defaultdict

def generate_manifest(root_dir):
    """
    Walks the repository and returns a dictionary of valid files grouped by
    their top-level directory.
    """
    ignore_dirs = {".venv", "bin", "logs", ".git", "__pycache__", ".vscode", ".idea"}
    valid_exts = {".c", ".h", ".lua", ".glsl", ".vert", ".frag", ".py", ".md", ".txt", ".bat", ".sh"}

    # Dictionary to hold lists of files, grouped by top-level directory
    manifest_groups = defaultdict(list)

    for root, dirs, files in os.walk(root_dir):
        # Modify dirs in-place to prevent os.walk from entering ignored directories
        dirs[:] = [d for d in dirs if d not in ignore_dirs]

        for file in files:
            # Check if file has a valid extension OR is exactly "LICENSE"
            if any(file.endswith(ext) for ext in valid_exts) or file == "LICENSE":
                # Get relative path and ensure forward slashes
                filepath = os.path.relpath(os.path.join(root, file), root_dir)
                filepath = filepath.replace(os.sep, "/")

                # Determine the top-level directory for grouping
                parts = filepath.split("/")
                group = parts[0] if len(parts) > 1 else "Root"

                manifest_groups[group].append(filepath)

    return manifest_groups

def print_manifest(groups):
    """
    Prints the grouped files in perfect Python syntax for copy-pasting.
    """
    print("INGESTION_MANIFEST = [")

    for group_name in sorted(groups.keys()):
        # Format the comment nicely (e.g., "host" -> "# Host")
        display_name = group_name.capitalize() if group_name != "Root" else "Root Files"
        print(f"    # {display_name}")

        # Print each file in alphabetical order within the group
        for filepath in sorted(groups[group_name]):
            print(f'    "{filepath}",')

        print("")  # Blank line between groups for visual breathing room

    print("]")

if __name__ == "__main__":
    # If executed from inside the /python folder, default to the parent directory.
    # Otherwise, default to the current working directory.
    default_dir = ".." if os.path.basename(os.getcwd()) == "python" else "."

    # Allow overriding the target directory via command line argument
    target_dir = sys.argv[1] if len(sys.argv) > 1 else default_dir

    groups = generate_manifest(target_dir)
    print_manifest(groups)
