#!/bin/bash

echo "Starting streamlit server at $(date)" >> /var/log/codedeploy-install.log

# Navigate to the application directory
cd /home/ec2-user/streamlit-app

# Kill any existing streamlit processes
pkill -f streamlit || true

# Wait a moment
sleep 2

# Start the Streamlit application in the background
nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

echo "Streamlit server start command executed at $(date)" >> /var/log/codedeploy-install.log

# Exit successfully (don't wait to check if it's running)
exit 0
