#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Python 3 and pip if not already installed
yum install -y python3 python3-pip

# Install or upgrade pip
python3 -m pip install --upgrade pip

# Navigate to the application directory
cd /home/ec2-user/streamlit-app

# Install Python dependencies
python3 -m pip install -r requirements.txt

# Change ownership of the application directory
chown -R ec2-user:ec2-user /home/ec2-user/streamlit-app
