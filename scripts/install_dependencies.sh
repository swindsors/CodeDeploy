#!/bin/bash
set -e

# Log all output for debugging
exec > >(tee -a /var/log/codedeploy-install.log) 2>&1
echo "Starting install_dependencies.sh at $(date)"

# Update system packages
echo "Updating system packages..."
yum update -y

# Install Python 3 and pip if not already installed
echo "Installing Python 3 and pip..."
yum install -y python3 python3-pip

# Install or upgrade pip
echo "Upgrading pip..."
python3 -m pip install --upgrade pip

# Wait for the application directory to be created by CodeDeploy
echo "Waiting for application directory..."
sleep 5

# Navigate to the application directory
if [ -d "/home/ec2-user/streamlit-app" ]; then
    cd /home/ec2-user/streamlit-app
    echo "Changed to application directory"
else
    echo "Application directory not found, creating it..."
    mkdir -p /home/ec2-user/streamlit-app
    cd /home/ec2-user/streamlit-app
fi

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies from requirements.txt..."
    python3 -m pip install -r requirements.txt
else
    echo "requirements.txt not found, installing streamlit directly..."
    python3 -m pip install streamlit==1.28.1
fi

# Change ownership of the application directory
echo "Setting ownership..."
chown -R ec2-user:ec2-user /home/ec2-user/streamlit-app

echo "install_dependencies.sh completed successfully at $(date)"
