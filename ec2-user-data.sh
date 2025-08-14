#!/bin/bash
set -e

# Update the system
yum update -y

# Install required packages
yum install -y ruby wget python3 python3-pip

# Install CodeDeploy agent
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start and enable CodeDeploy agent
service codedeploy-agent start
chkconfig codedeploy-agent on

# Install Python dependencies globally
python3 -m pip install --upgrade pip

# Create application directory
mkdir -p /home/ec2-user/streamlit-app
chown -R ec2-user:ec2-user /home/ec2-user/streamlit-app

# Create log file for streamlit
touch /home/ec2-user/streamlit.log
chown ec2-user:ec2-user /home/ec2-user/streamlit.log

# Configure security group to allow traffic on port 8501 (done via AWS Console or CLI)
# Note: You'll need to manually configure the security group to allow inbound traffic on port 8501

echo "EC2 instance setup complete for CodeDeploy and Streamlit"
