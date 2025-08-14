#!/bin/bash

# Make all scripts executable
chmod +x scripts/install_dependencies.sh
chmod +x scripts/start_server.sh
chmod +x scripts/stop_server.sh
chmod +x ec2-user-data.sh

echo "All scripts are now executable"
echo "Ready to deploy to GitHub and AWS!"
