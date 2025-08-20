#!/bin/bash

echo "=== EC2 Streamlit Access Troubleshooting ==="
echo "Running at $(date)"
echo

# Get the public IP address
echo "=== EC2 Instance Information ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)

if [ -n "$PUBLIC_IP" ]; then
    echo "Public IP: $PUBLIC_IP"
    echo "Access your Streamlit app at: http://$PUBLIC_IP:8501"
else
    echo "Could not retrieve public IP address"
fi

if [ -n "$PRIVATE_IP" ]; then
    echo "Private IP: $PRIVATE_IP"
else
    echo "Could not retrieve private IP address"
fi

echo

# Check if streamlit is running
echo "=== Streamlit Process Check ==="
if pgrep -f streamlit > /dev/null; then
    echo "✅ Streamlit is running"
    echo "Streamlit processes:"
    ps aux | grep streamlit | grep -v grep
else
    echo "❌ Streamlit is not running"
    echo "You may need to start it with:"
    echo "  cd /home/ec2-user/streamlit-app"
    echo "  python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0"
fi

echo

# Check if port 8501 is listening
echo "=== Port 8501 Check ==="
if netstat -tuln 2>/dev/null | grep -q ":8501 "; then
    echo "✅ Port 8501 is listening"
    netstat -tuln | grep ":8501 "
elif ss -tuln 2>/dev/null | grep -q ":8501 "; then
    echo "✅ Port 8501 is listening"
    ss -tuln | grep ":8501 "
else
    echo "❌ Port 8501 is not listening"
    echo "Make sure Streamlit is running and bound to 0.0.0.0:8501"
fi

echo

# Test local connectivity
echo "=== Local Connectivity Test ==="
if command -v curl >/dev/null 2>&1; then
    echo "Testing local connection to Streamlit..."
    if curl -s --connect-timeout 5 http://localhost:8501 >/dev/null; then
        echo "✅ Local connection to Streamlit successful"
    else
        echo "❌ Local connection to Streamlit failed"
    fi
else
    echo "curl not available for testing"
fi

echo

# Security group information
echo "=== Security Group Recommendations ==="
echo "To access your Streamlit app from the internet, ensure your EC2 security group allows:"
echo "  - Inbound rule: Custom TCP, Port 8501, Source: 0.0.0.0/0 (or your specific IP)"
echo "  - Protocol: TCP"
echo "  - Port Range: 8501"
echo

echo "=== AWS CLI Commands to Add Security Group Rule ==="
echo "If you have AWS CLI configured, you can add the rule with:"
echo "  aws ec2 authorize-security-group-ingress \\"
echo "    --group-id sg-xxxxxxxxx \\"
echo "    --protocol tcp \\"
echo "    --port 8501 \\"
echo "    --cidr 0.0.0.0/0"
echo
echo "Replace 'sg-xxxxxxxxx' with your actual security group ID"

echo

# Final summary
echo "=== Summary ==="
if [ -n "$PUBLIC_IP" ]; then
    echo "🌐 Your Streamlit app should be accessible at: http://$PUBLIC_IP:8501"
    echo
    echo "If the link doesn't work, check:"
    echo "1. Security group allows inbound traffic on port 8501"
    echo "2. Streamlit is running (check above)"
    echo "3. Your local firewall/network allows outbound connections to port 8501"
else
    echo "❌ Could not determine public IP address"
fi
