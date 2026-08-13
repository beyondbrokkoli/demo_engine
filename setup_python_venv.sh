#!/usr/bin/env bash

# setup_python_env.sh
# Automates setting up a virtual environment and installing Python AI dependencies

VENV_DIR=".venv"

echo "=== Setting up Python AI Environment ==="

# 1. Create the virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "[INFO] Creating fresh virtual environment in ./$VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "[FATAL] Failed to create virtual environment. Is python3 installed?"
        exit 1
    fi
else
    echo "[INFO] Virtual environment already exists in ./$VENV_DIR."
fi

# 2. Activate the virtual environment
echo "[INFO] Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# 3. Upgrade pip to ensure clean installations
echo "[INFO] Upgrading pip..."
pip install --quiet --upgrade pip

# 4. Install the required external packages
echo "[INFO] Installing dependencies (requests, qdrant-client, openai)..."
pip install requests qdrant-client openai

# 5. Save the exact dependency tree
echo "[INFO] Generating requirements.txt for project tracking..."
pip freeze > python/requirements.txt
echo " [OK] Saved to python/requirements.txt"

echo "----------------------------------------"
echo "[SUCCESS] Environment is ready."
echo ""
echo "To activate this environment in your current terminal, run:"
echo "    source $VENV_DIR/bin/activate"
