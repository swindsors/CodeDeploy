#!/bin/bash

echo "=== Streamlit EC2 Troubleshooting Script ==="
echo "Running at $(date)"
echo

# Check current user
echo "Current user: $(whoami)"
echo "Home directory: $HOME"
echo

# Check Python installation
echo "=== Python Installation ==="
python3 --version
which python3
echo

# Check pip installation
echo "=== Pip Installation ==="
python3 -m pip --version
which pip3
echo

# Check if streamlit is installed system-wide
echo "=== System-wide Streamlit Check ==="
python3 -c "import streamlit; print('System streamlit version:', streamlit.__version__)" 2>/dev/null || echo "Streamlit not found system-wide"
echo

# Check if streamlit is installed for current user
echo "=== User-specific Streamlit Check ==="
export PATH="$HOME/.local/bin:$PATH"
python3 -c "import streamlit; print('User streamlit version:', streamlit.__version__)" 2>/dev/null || echo "Streamlit not found for user"
echo

# Show PATH
echo "=== Current PATH ==="
echo $PATH
echo

# Check if streamlit executable exists
echo "=== Streamlit Executable Check ==="
which streamlit 2>/dev/null || echo "streamlit command not found in PATH"
ls -la $HOME/.local/bin/streamlit 2>/dev/null || echo "streamlit not found in user's local bin"
echo

# Install streamlit if missing
echo "=== Installing/Updating Streamlit ==="
echo "Installing streamlit system-wide..."
sudo python3 -m pip install streamlit==1.28.1

echo "Installing streamlit for current user..."
python3 -m pip install --user streamlit==1.28.1

# Update PATH in .bashrc if needed
echo "=== Updating PATH in .bashrc ==="
if ! grep -q '\.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "Added .local/bin to PATH in .bashrc"
else
    echo ".local/bin already in .bashrc PATH"
fi

# Source .bashrc to update current session
source ~/.bashrc 2>/dev/null || true

# Final verification
echo "=== Final Verification ==="
export PATH="$HOME/.local/bin:$PATH"
python3 -c "import streamlit; print('Final check - Streamlit version:', streamlit.__version__)" || echo "ERROR: Streamlit still not working"

echo
echo "=== Troubleshooting Complete ==="
echo "If streamlit is still not working, check the logs above for errors."
echo "You may need to restart your terminal session or run: source ~/.bashrc"
