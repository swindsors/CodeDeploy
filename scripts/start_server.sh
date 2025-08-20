#!/bin/bash

# Use a log file that ec2-user can write to
LOG_FILE="/home/ec2-user/streamlit-startup.log"

echo "Starting streamlit server at $(date)" >> $LOG_FILE

# Navigate to the application directory
cd /home/ec2-user/streamlit-app

# Kill any existing streamlit processes
pkill -f streamlit || true

# Wait a moment
sleep 3

# Check if app.py exists
if [ ! -f "app.py" ]; then
    echo "ERROR: app.py not found in $(pwd)" >> $LOG_FILE
    ls -la >> $LOG_FILE
    exit 1
fi

# Verify streamlit is available
echo "Checking streamlit installation..." >> $LOG_FILE
python3 -c "import streamlit; print('Streamlit version:', streamlit.__version__)" >> $LOG_FILE 2>&1

# Set PATH to include user's local bin directory
export PATH="/home/ec2-user/.local/bin:$PATH"

# Start the Streamlit application in the background
echo "Executing: nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0" >> $LOG_FILE
nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

# Wait and check if it started
sleep 5
if pgrep -f streamlit > /dev/null; then
    echo "Streamlit server started successfully at $(date)" >> $LOG_FILE
    echo "Server is running on port 8501"
else
    echo "ERROR: Streamlit server failed to start at $(date)" >> $LOG_FILE
    echo "Streamlit log contents:" >> $LOG_FILE
    cat /home/ec2-user/streamlit.log >> $LOG_FILE
fi

exit 0
