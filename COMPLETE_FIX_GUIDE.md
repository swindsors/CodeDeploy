# Complete Fix Guide for Your Issues

You have two main problems to solve:
1. **Streamlit app running but not accessible from browser**
2. **CodeConnections permissions error in your pipeline**

## PART 1: Fix Streamlit Connectivity Issue

### Step 1: Run the Diagnostic Script

1. **Copy the diagnostic script to your EC2 instance:**
   ```bash
   # From your local machine, copy the script
   scp -i your-key.pem diagnose_streamlit.sh ec2-user@YOUR_EC2_PUBLIC_IP:/home/ec2-user/
   ```

2. **SSH into your EC2 instance and run the diagnostic:**
   ```bash
   ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
   chmod +x diagnose_streamlit.sh
   ./diagnose_streamlit.sh
   ```

### Step 2: Most Likely Fix - Security Group Configuration

**This is the #1 cause of your issue.** Your EC2 security group probably doesn't allow inbound traffic on port 8501.

1. **Go to AWS Console → EC2 → Instances**
2. **Select your EC2 instance**
3. **Click on the "Security" tab**
4. **Click on the security group name** (it will be a link)
5. **Click "Edit inbound rules"**
6. **Add a new rule:**
   - **Type:** Custom TCP
   - **Port range:** 8501
   - **Source:** 0.0.0.0/0 (or your IP for better security)
   - **Description:** Streamlit app access
7. **Click "Save rules"**

### Step 3: Get Your EC2 Public IP Address

**CRITICAL: You CANNOT use http://0.0.0.0:8501 - this will never work!**

Get your actual EC2 public IP address:

**Method 1 - AWS Console (Easiest):**
1. Go to **AWS Console → EC2 → Instances**
2. Select your EC2 instance
3. Look for **"Public IPv4 address"** in the instance details
4. Copy this IP address (e.g., `54.123.45.67`)

**Method 2 - SSH into EC2 and run:**
```bash
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
```

### Step 4: Test Access with Correct URL

After fixing the security group AND getting your public IP:
1. **Use the ACTUAL public IP** (not 0.0.0.0, not localhost, not 127.0.0.1)
2. **Open browser and go to:** `http://YOUR_ACTUAL_EC2_PUBLIC_IP:8501`
   - Example: `http://54.123.45.67:8501`
3. **You should now see your Streamlit app!**

### Step 5: If Still Not Working

If the security group fix doesn't work, run these commands on your EC2 instance:

```bash
# Stop any existing Streamlit processes
pkill -f streamlit

# Navigate to your app directory
cd /home/ec2-user/streamlit-app
# OR if files are in home directory:
cd /home/ec2-user

# Start Streamlit manually to see any error messages
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
```

## PART 2: Fix CodeConnections Permissions Error

### Step 1: Find Your CodePipeline Service Role

1. **Go to AWS Console → CodePipeline**
2. **Click on your pipeline:** `streamlit-deployment-pipeline`
3. **Click the "Settings" tab**
4. **Find the "Service role ARN"** - it looks like:
   `arn:aws:iam::804711833877:role/service-role/AWSCodePipelineServiceRole-us-east-1-XXXXX`
5. **Copy the role name** (the part after the last `/`)

### Step 2: Add CodeConnections Permissions

1. **Go to AWS Console → IAM → Roles**
2. **Search for your CodePipeline service role** (from Step 1)
3. **Click on the role name**
4. **Click "Add permissions" → "Attach policies"**
5. **Search for and attach these policies:**
   - `AWSCodeStarConnectionsReadOnlyAccess`
   - `AWSCodeStarConnectionsUserAccess`
6. **Click "Add permissions"**

### Step 3: Verify GitHub Connection

1. **Go to AWS Console → Developer Tools → Connections**
2. **Find your connection with ID:** `21edde58-9108-4365-9c7c-de569ad473d8`
3. **Check the status:**
   - If **"Available"** - you're good
   - If **"Pending"** - click on it and complete GitHub authorization

### Step 4: Test Your Pipeline

1. **Go back to CodePipeline Console**
2. **Click on your pipeline**
3. **Click "Release change"** to trigger a new run
4. **The Source stage should now complete successfully**

## PART 3: Alternative Solutions

### If CodeConnections Permissions Don't Work

Create a custom policy instead:

1. **In your CodePipeline service role, click "Add permissions" → "Create inline policy"**
2. **Click "JSON" tab and paste:**
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "codeconnections:UseConnection",
                   "codeconnections:GetConnection",
                   "codeconnections:ListConnections"
               ],
               "Resource": "arn:aws:codeconnections:us-east-1:804711833877:connection/21edde58-9108-4365-9c7c-de569ad473d8"
           }
       ]
   }
   ```
3. **Policy name:** `CodeConnectionsAccess`
4. **Click "Create policy"**

### If Streamlit Still Won't Start

Try this manual startup process:

```bash
# SSH into your instance
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Install Streamlit if missing
python3 -m pip install --user streamlit==1.28.1

# Navigate to app directory
cd /home/ec2-user/streamlit-app

# Start with verbose output to see errors
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0 --logger.level=debug
```

## PART 4: Verification Checklist

After completing both fixes:

### ✅ Streamlit App Working
- [ ] Security group allows port 8501
- [ ] Can access `http://YOUR_EC2_PUBLIC_IP:8501` in browser
- [ ] App loads and functions correctly

### ✅ Pipeline Working
- [ ] CodePipeline service role has CodeConnections permissions
- [ ] GitHub connection shows "Available" status
- [ ] Pipeline runs successfully without permissions errors
- [ ] App deploys automatically when you push to GitHub

## PART 5: Test End-to-End

1. **Make a small change to your app.py file**
2. **Commit and push to GitHub:**
   ```bash
   git add .
   git commit -m "Test automatic deployment"
   git push
   ```
3. **Watch your pipeline run in CodePipeline Console**
4. **Verify the updated app appears at your EC2 URL**

## Quick Reference Commands

```bash
# Check if Streamlit is running
ps aux | grep streamlit

# Check if port 8501 is listening
sudo netstat -tlnp | grep 8501

# Start Streamlit manually
cd /home/ec2-user/streamlit-app
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0

# Stop Streamlit
pkill -f streamlit

# Check logs
cat /home/ec2-user/streamlit.log
```

## Need Help?

If you're still having issues after following this guide:

1. **Run the diagnostic script** and share the output
2. **Check the specific error messages** in logs
3. **Verify each step was completed exactly as described**

The most common issues are:
- **Security group not configured** (95% of connectivity issues)
- **Wrong IAM permissions** (95% of pipeline issues)
