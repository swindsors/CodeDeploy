# Streamlit App Troubleshooting Guide

This guide helps you diagnose and fix issues with your Streamlit app deployment on EC2.

## Quick Status Check Commands

Run these commands in order to quickly check your app status:

```bash
# SSH into your EC2 instance first
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# 1. Check if Streamlit process is running
ps aux | grep streamlit

# 2. Check if port 8501 is listening
sudo netstat -tlnp | grep 8501

# 3. Check deployment logs
sudo tail -10 /var/log/codedeploy-install.log

# 4. Check Streamlit application logs
cat /home/ec2-user/streamlit.log

# 5. Test local connection
curl -I http://localhost:8501
```

## Detailed Verification Methods

### 1. Process Check
```bash
ps aux | grep streamlit
```

**What you should see:**
```
ec2-user  12345  0.1  2.3  123456  45678 ?  S  09:00  0:01 python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
```

**If you see only:**
```
ec2-user   60807  0.0  0.2 222316  2028 pts/1    S+   12:53   0:00 grep --color=auto streamlit
```
This means Streamlit is NOT running.

### 2. Port Check
```bash
sudo netstat -tlnp | grep 8501
# OR
sudo ss -tlnp | grep 8501
```

**What you should see:**
```
tcp  0  0  0.0.0.0:8501  0.0.0.0:*  LISTEN  12345/python3
```

**If you see nothing:** Port 8501 is not being used, meaning Streamlit isn't running.

### 3. Log Analysis

#### Deployment Logs
```bash
sudo cat /var/log/codedeploy-install.log
```

**Look for:**
- "Streamlit server started successfully"
- Any ERROR messages
- Package installation issues

#### Streamlit Application Logs
```bash
cat /home/ec2-user/streamlit.log
```

**Common error messages:**
- Module not found errors
- Port binding issues
- Permission errors

### 4. Local Connection Test
```bash
# Test if the app responds locally
curl http://localhost:8501

# More detailed test
curl -v http://localhost:8501
```

**Expected response:**
```
HTTP/1.1 200 OK
Content-Type: text/html
```

### 5. Browser Access Test
Open your web browser and navigate to:
```
http://YOUR_EC2_PUBLIC_IP:8501
```

**Replace YOUR_EC2_PUBLIC_IP with your actual EC2 public IP address.**

## Common Issues and Solutions

### Issue 1: "No instances found for deployment group"
**Symptoms:** CodeDeploy can't find your EC2 instance

**Solution:**
1. Check EC2 instance tags:
   ```bash
   # In AWS Console: EC2 → Instances → Select your instance → Tags tab
   ```
2. Update deployment group tags to match exactly (case-sensitive)
3. Ensure you selected "Amazon EC2 instances" not "On-premises instances"

### Issue 2: "Too many instances failed deployment"
**Symptoms:** CodeDeploy finds instance but deployment fails

**Solution:**
1. Check CodeDeploy agent status:
   ```bash
   sudo service codedeploy-agent status
   sudo service codedeploy-agent restart
   ```

2. Check script permissions:
   ```bash
   sudo chmod +x /home/ec2-user/streamlit-app/scripts/*.sh
   ```

3. Check deployment logs:
   ```bash
   sudo tail -50 /var/log/aws/codedeploy-agent/codedeploy-agent.log
   ```

### Issue 3: Streamlit Process Not Running
**Symptoms:** `ps aux | grep streamlit` shows no running process

**Solutions:**

1. **Check if app files exist:**
   ```bash
   ls -la /home/ec2-user/streamlit-app/
   ```

2. **Manually start Streamlit:**
   ```bash
   cd /home/ec2-user/streamlit-app
   python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
   ```

3. **Check if Streamlit is installed:**
   ```bash
   python3 -m pip list | grep streamlit
   # If not found, install it:
   python3 -m pip install --user streamlit==1.28.1
   ```

4. **Run the start script manually:**
   ```bash
   /home/ec2-user/streamlit-app/scripts/start_server.sh
   ```

### Issue 4: Package Installation Conflicts
**Symptoms:** Errors like "Cannot uninstall requests 2.25.1, RECORD file not found"

**Solution:** This is already fixed in the latest scripts using `--user` flag, but if you encounter it:
```bash
python3 -m pip install --user --force-reinstall streamlit==1.28.1
```

### Issue 5: Port 8501 Not Accessible from Browser
**Symptoms:** Can curl locally but can't access from browser

**Solutions:**

1. **Check Security Group:**
   - Go to EC2 Console → Security Groups
   - Find your instance's security group
   - Ensure inbound rule exists: Type: Custom TCP, Port: 8501, Source: 0.0.0.0/0

2. **Check if Streamlit is binding to all interfaces:**
   ```bash
   sudo netstat -tlnp | grep 8501
   ```
   Should show `0.0.0.0:8501` not `127.0.0.1:8501`

3. **Test with telnet:**
   ```bash
   # From your local machine
   telnet YOUR_EC2_PUBLIC_IP 8501
   ```

### Issue 6: CodeDeploy Agent Not Running
**Symptoms:** Deployments fail immediately

**Solutions:**
```bash
# Check agent status
sudo service codedeploy-agent status

# Start the agent
sudo service codedeploy-agent start

# Enable auto-start
sudo chkconfig codedeploy-agent on

# Check agent logs
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

## Manual Recovery Steps

If automatic deployment fails, you can manually deploy and start the app:

### 1. Manual File Deployment
```bash
# Create directory
sudo mkdir -p /home/ec2-user/streamlit-app
sudo chown -R ec2-user:ec2-user /home/ec2-user/streamlit-app

# Copy files from your local machine or re-clone from GitHub
cd /home/ec2-user/streamlit-app
# ... copy your app.py, requirements.txt, etc.
```

### 2. Manual Dependency Installation
```bash
cd /home/ec2-user/streamlit-app
python3 -m pip install --user -r requirements.txt
# OR
python3 -m pip install --user streamlit==1.28.1
```

### 3. Manual App Start
```bash
cd /home/ec2-user/streamlit-app
nohup python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 > /home/ec2-user/streamlit.log 2>&1 &
```

### 4. Verify Manual Start
```bash
# Check process
ps aux | grep streamlit

# Check port
sudo netstat -tlnp | grep 8501

# Check logs
tail -f /home/ec2-user/streamlit.log
```

## Getting Help

If you're still having issues:

1. **Collect diagnostic information:**
   ```bash
   # Save all relevant logs
   sudo cat /var/log/codedeploy-install.log > debug-info.txt
   cat /home/ec2-user/streamlit.log >> debug-info.txt
   sudo tail -50 /var/log/aws/codedeploy-agent/codedeploy-agent.log >> debug-info.txt
   ps aux | grep streamlit >> debug-info.txt
   sudo netstat -tlnp | grep 8501 >> debug-info.txt
   ```

2. **Check AWS Console:**
   - CodeDeploy Console → Applications → streamlit-hello-world → Deployment history
   - EC2 Console → Instances → Your instance → System log

3. **Common commands for debugging:**
   ```bash
   # Check system resources
   free -h
   df -h
   
   # Check Python version
   python3 --version
   
   # Check pip version
   python3 -m pip --version
   
   # List installed packages
   python3 -m pip list
   
   # Check network connectivity
   ping google.com
   ```

Remember to replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 instance's public IP address in all commands and URLs.
