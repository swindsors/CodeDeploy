#!/bin/bash
set -e

# Navigate to the application directory
cd /home/ec2-user/streamlit-app

# Kill any existing streamlit processes
pkill -f streamlit || true

# Start the Streamlit application in the background
nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

# Wait a moment for the server to start
sleep 5

# Check if the process is running
if pgrep -f streamlit > /dev/null; then
    echo "Streamlit server started successfully"
else
    echo "Failed to start Streamlit server"
    exit 1
fi
