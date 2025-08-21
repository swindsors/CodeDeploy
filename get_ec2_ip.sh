#!/bin/bash

echo "=== Finding Your EC2 Public IP Address ==="
echo ""

echo "Method 1: Check AWS Console"
echo "1. Go to AWS Console → EC2 → Instances"
echo "2. Select your instance"
echo "3. Look for 'Public IPv4 address' in the details"
echo ""

echo "Method 2: Run this command ON YOUR EC2 INSTANCE (via SSH):"
echo "curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
echo ""

echo "Method 3: If you have AWS CLI configured locally:"
echo "aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==\`Name\`].Value|[0]]' --output table"
echo ""

echo "=== IMPORTANT ==="
echo "DO NOT use http://0.0.0.0:8501 - this will never work!"
echo "DO NOT use http://127.0.0.1:8501 - this only works from inside the EC2 instance"
echo "DO NOT use http://localhost:8501 - this only works from inside the EC2 instance"
echo ""
echo "You MUST use: http://YOUR_ACTUAL_EC2_PUBLIC_IP:8501"
echo "Example: http://54.123.45.67:8501"
echo ""

echo "=== Quick Fix Steps ==="
echo "1. Get your EC2 public IP using one of the methods above"
echo "2. Make sure your security group allows port 8501 (Custom TCP, 0.0.0.0/0)"
echo "3. Use the correct URL: http://YOUR_EC2_PUBLIC_IP:8501"
echo ""
