#!/bin/bash
set -e

# Kill any existing streamlit processes
pkill -f streamlit || true

echo "Streamlit server stopped"
