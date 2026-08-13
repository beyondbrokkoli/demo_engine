# ingest_validators.py
import os
import sys
import re

def validate_lua_invariants(filepath, source_code, expected_deps):
    matches = re.findall(r'require\s*\(\s*["\']([^"\']+)["\']\s*\)|require\s+["\']([^"\']+)["\']', source_code)

    actual_requires = set()
    for match in matches:
        req = match[0] if match[0] else match[1]
        if req not in ["ffi", "math", "bit", "os", "io", "string"]:
            actual_requires.add(req)

    expected_requires = set(expected_deps)
    expected_requires = {dep for dep in expected_requires if dep not in ["ffi", "math", "bit"]}

    if actual_requires != expected_requires:
        print(f"\n[FATAL INVARIANT] Architecture drift detected in '{filepath}'")
        print(f" |- Expected (deps_lua.md): {expected_requires}")
        print(f" |- Actual (Lua source):   {actual_requires}")
        sys.exit(1)


def validate_include_invariants(file_name, source_code, expected_deps, domain="C"):
    matches = re.findall(r'#include\s+"([^"]+)"', source_code)

    actual_requires = set()
    for match in matches:
        actual_requires.add(os.path.basename(match))

    expected_requires = set(expected_deps)

    if actual_requires != expected_requires:
        print(f"\n[FATAL INVARIANT] {domain} Architecture drift detected in '{file_name}'")
        print(f" |- Expected (deps_{domain.lower()}.md): {expected_requires}")
        print(f" |- Actual ({domain} source):     {actual_requires}")
        sys.exit(1)
