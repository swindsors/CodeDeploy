#!/bin/bash

# Log everything for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Don't exit on errors initially
set +e

# Update the system
echo "Updating system packages..."
yum update -y

# Install required packages with more explicit approach
echo "Installing required packages..."
yum install -y ruby wget

# Install Python 3 explicitly for Amazon Linux 2023
echo "Installing Python 3..."
yum install -y python3 python3-pip python3-devel

# Verify Python installation
echo "Verifying Python installation..."
python3 --version
pip3 --version

# Install CodeDeploy agent
echo "Installing CodeDeploy agent..."
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start and enable CodeDeploy agent
echo "Starting CodeDeploy agent..."
service codedeploy-agent start
chkconfig codedeploy-agent on

# Verify CodeDeploy agent is running
service codedeploy-agent status

# Upgrade pip
echo "Upgrading pip..."
python3 -m pip install --upgrade pip

# Create application directory
echo "Creating application directory..."
mkdir -p /home/ec2-user/streamlit-app
chown -R ec2-user:ec2-user /home/ec2-user/streamlit-app

# Create log file for streamlit
touch /home/ec2-user/streamlit.log
chown ec2-user:ec2-user /home/ec2-user/streamlit.log

# Install streamlit system-wide to ensure it's available for all users
echo "Pre-installing Streamlit system-wide..."
python3 -m pip install streamlit==1.28.1

# Also install for ec2-user specifically
echo "Installing Streamlit for ec2-user..."
sudo -u ec2-user python3 -m pip install --user streamlit==1.28.1

# Add ec2-user's local bin to PATH in .bashrc
echo 'export PATH="/home/ec2-user/.local/bin:$PATH"' >> /home/ec2-user/.bashrc
chown ec2-user:ec2-user /home/ec2-user/.bashrc

echo "EC2 instance setup complete for CodeDeploy and Streamlit at $(date)"
echo "Python version: $(python3 --version)"
echo "Pip version: $(python3 -m pip --version)"
echo "CodeDeploy agent status: $(service codedeploy-agent status)"
