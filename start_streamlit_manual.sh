#!/bin/bash

echo "=== Manual Streamlit Startup Script ==="
echo "Starting at $(date)"

# Set up environment
export PATH="/home/ec2-user/.local/bin:$PATH"
cd /home/ec2-user/streamlit-app

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    echo "ERROR: app.py not found. Make sure you're running this from the correct directory."
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
    exit 1
fi

# Kill any existing streamlit processes
echo "Stopping any existing streamlit processes..."
pkill -f streamlit || echo "No existing streamlit processes found"

# Wait a moment
sleep 2

# Verify streamlit is available
echo "Checking streamlit installation..."
python3 -c "import streamlit; print('Streamlit version:', streamlit.__version__)" || {
    echo "ERROR: Streamlit not found. Installing now..."
    python3 -m pip install --user streamlit==1.28.1
}

# Start streamlit
echo "Starting Streamlit server..."
echo "Access your app at: http://your-ec2-public-ip:8501"
echo "Press Ctrl+C to stop the server"
echo

# Run streamlit in foreground so you can see the output
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
