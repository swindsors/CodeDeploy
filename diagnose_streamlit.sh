#!/bin/bash

echo "=== Streamlit Connectivity Diagnostic Script ==="
echo "Run this script on your EC2 instance to diagnose connectivity issues"
echo ""

echo "1. Checking if Streamlit process is running..."
STREAMLIT_PROCESS=$(ps aux | grep streamlit | grep -v grep)
if [ -n "$STREAMLIT_PROCESS" ]; then
    echo "✓ Streamlit process found:"
    echo "$STREAMLIT_PROCESS"
else
    echo "✗ No Streamlit process running"
fi
echo ""

echo "2. Checking if port 8501 is listening..."
PORT_CHECK=$(sudo netstat -tlnp | grep 8501)
if [ -n "$PORT_CHECK" ]; then
    echo "✓ Port 8501 is listening:"
    echo "$PORT_CHECK"
else
    echo "✗ Port 8501 is not listening"
fi
echo ""

echo "3. Testing local connection..."
LOCAL_TEST=$(curl -s -I http://localhost:8501 2>/dev/null | head -1)
if [[ "$LOCAL_TEST" == *"200 OK"* ]]; then
    echo "✓ Local connection successful: $LOCAL_TEST"
else
    echo "✗ Local connection failed: $LOCAL_TEST"
fi
echo ""

echo "4. Checking Streamlit logs..."
if [ -f "/home/ec2-user/streamlit.log" ]; then
    echo "✓ Streamlit log exists. Last 10 lines:"
    tail -10 /home/ec2-user/streamlit.log
else
    echo "✗ No Streamlit log found at /home/ec2-user/streamlit.log"
fi
echo ""

echo "5. Checking if app files exist..."
if [ -f "/home/ec2-user/streamlit-app/app.py" ]; then
    echo "✓ App files found in /home/ec2-user/streamlit-app/"
    ls -la /home/ec2-user/streamlit-app/
elif [ -f "/home/ec2-user/app.py" ]; then
    echo "✓ App files found in /home/ec2-user/"
    ls -la /home/ec2-user/app.py
else
    echo "✗ No app.py found in expected locations"
fi
echo ""

echo "6. Checking Python and Streamlit installation..."
PYTHON_VERSION=$(python3 --version 2>/dev/null)
echo "Python version: $PYTHON_VERSION"

STREAMLIT_VERSION=$(python3 -m pip show streamlit 2>/dev/null | grep Version)
if [ -n "$STREAMLIT_VERSION" ]; then
    echo "✓ Streamlit installed: $STREAMLIT_VERSION"
else
    echo "✗ Streamlit not found in pip list"
fi
echo ""

echo "7. Getting EC2 instance metadata..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo ""

echo "=== SUMMARY ==="
echo "If Streamlit is running but you can't connect from browser:"
echo "1. Check your EC2 Security Group allows inbound TCP port 8501 from 0.0.0.0/0"
echo "2. Try accessing: http://$PUBLIC_IP:8501"
echo ""
echo "If Streamlit is not running:"
echo "1. Try starting manually: cd /home/ec2-user/streamlit-app && python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0"
echo "2. Check the logs above for error messages"
echo ""
echo "=== END DIAGNOSTIC ==="
