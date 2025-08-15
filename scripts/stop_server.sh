#!/bin/bash

echo "Stopping streamlit server at $(date)" >> /var/log/codedeploy-install.log

# Kill any existing streamlit processes
pkill -f streamlit || true

echo "Streamlit server stopped at $(date)" >> /var/log/codedeploy-install.log

# Exit successfully
exit 0
