#!/bin/bash

# Simple logging
echo "Starting install_dependencies.sh at $(date)" >> /var/log/codedeploy-install.log

# Don't exit on errors initially - let's see what happens
set +e

# Update system packages
echo "Updating system packages..." >> /var/log/codedeploy-install.log
yum update -y >> /var/log/codedeploy-install.log 2>&1

# Install Python 3 and pip if not already installed
echo "Installing Python 3 and pip..." >> /var/log/codedeploy-install.log
yum install -y python3 python3-pip >> /var/log/codedeploy-install.log 2>&1

# Install streamlit system-wide to ensure it's available for all users
echo "Installing streamlit system-wide..." >> /var/log/codedeploy-install.log
python3 -m pip install streamlit==1.28.1 >> /var/log/codedeploy-install.log 2>&1

# Also install for ec2-user specifically as backup
echo "Installing streamlit for ec2-user..." >> /var/log/codedeploy-install.log
sudo -u ec2-user python3 -m pip install --user streamlit==1.28.1 >> /var/log/codedeploy-install.log 2>&1

echo "install_dependencies.sh completed at $(date)" >> /var/log/codedeploy-install.log

# Exit successfully
exit 0
