#!/bin/bash

echo "Starting streamlit server at $(date)" >> /var/log/codedeploy-install.log

# Navigate to the application directory
cd /home/ec2-user/streamlit-app

# Kill any existing streamlit processes
pkill -f streamlit || true

# Wait a moment
sleep 3

# Check if app.py exists
if [ ! -f "app.py" ]; then
    echo "ERROR: app.py not found in $(pwd)" >> /var/log/codedeploy-install.log
    ls -la >> /var/log/codedeploy-install.log
    exit 1
fi

# Make sure streamlit is installed (using --user flag)
python3 -m pip install --user streamlit==1.28.1 >> /var/log/codedeploy-install.log 2>&1

# Start the Streamlit application in the background
echo "Executing: nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0" >> /var/log/codedeploy-install.log
nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &

# Wait and check if it started
sleep 5
if pgrep -f streamlit > /dev/null; then
    echo "Streamlit server started successfully at $(date)" >> /var/log/codedeploy-install.log
else
    echo "ERROR: Streamlit server failed to start at $(date)" >> /var/log/codedeploy-install.log
    echo "Streamlit log contents:" >> /var/log/codedeploy-install.log
    cat /home/ec2-user/streamlit.log >> /var/log/codedeploy-install.log
fi

exit 0
