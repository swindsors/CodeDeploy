# Complete Streamlit App Deployment Guide - Step by Step

This guide will walk you through deploying a Streamlit app to EC2 using AWS CodePipeline and CodeDeploy from scratch.

## Prerequisites

- AWS Account with admin permissions
- GitHub account
- Basic familiarity with AWS Console

## Step 1: Create and Push Your Code to GitHub

### 1.1 Create a New GitHub Repository
1. Go to GitHub.com and sign in
2. Click "New" to create a new repository
3. Name it something like `streamlit-codedeploy-demo`
4. Make it **Public** (easier for CodePipeline integration)
5. Click "Create repository"

### 1.2 Push Your Local Code
```bash
# In your local project directory (where all the files are)
git init
git add .
git commit -m "Initial commit: Streamlit app with CodeDeploy setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

**Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub username and repository name.**

## Step 2: Create IAM Roles (3 roles needed)

### 2.1 Create CodeDeploy Service Role
1. Go to **IAM Console** → **Roles** → **Create Role**
2. Select **AWS Service**
3. Select **CodeDeploy** from the service list
4. Select **CodeDeploy** use case (not CodeDeploy for EC2/On-premises)
5. Click **Next**
6. The policy `AWSCodeDeployRole` should be automatically attached
7. Click **Next**
8. Role name: `CodeDeployServiceRole`
9. Click **Create role**

### 2.2 Create EC2 Instance Role
1. Go to **IAM Console** → **Roles** → **Create Role**
2. Select **AWS Service**
3. Select **EC2**
4. Click **Next**
5. Search for and attach these policies:
   - `AmazonEC2RoleforAWSCodeDeploy`
   - `CloudWatchAgentServerPolicy` (optional, for logging)
6. Click **Next**
7. Role name: `EC2CodeDeployRole`
8. Click **Create role**

### 2.3 CodePipeline Service Role (We'll let AWS create this automatically)
We'll create this automatically when setting up CodePipeline in Step 6.

## Step 3: Launch EC2 Instance

### 3.1 Launch Instance
1. Go to **EC2 Console** → **Launch Instance**
2. **Name**: `streamlit-app-server`
3. **AMI**: Select **Amazon Linux 2023 AMI** (free tier eligible)
4. **Instance type**: `t2.micro` (free tier)
5. **Key pair**: Select an existing key pair or create a new one
6. Click **Advanced details** at the bottom

### 3.2 Configure Advanced Details
1. **IAM instance profile**: Select `EC2CodeDeployRole`
2. **User data**: Copy and paste the entire contents of the `ec2-user-data.sh` file from your project
3. Leave other settings as default

### 3.3 Configure Security Group
1. Click **Edit** next to Network settings
2. **Security group name**: `streamlit-app-sg`
3. Add these inbound rules:
   - **Rule 1**: SSH, Port 22, Source: My IP
   - **Rule 2**: Custom TCP, Port 8501, Source: 0.0.0.0/0 (for Streamlit)
4. Click **Launch instance**

### 3.4 Add Tags to Your Instance (CRITICAL)
1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **Actions** → **Instance settings** → **Manage tags**
4. Click **Add tag**
5. **Key**: `Name`
6. **Value**: `streamlit-app-server`
7. Click **Save**

**Write down this tag key and value - you'll need them exactly for CodeDeploy!**

## Step 4: Create CodeDeploy Application

### 4.1 Create Application
1. Go to **CodeDeploy Console** → **Applications** → **Create application**
2. **Application name**: `streamlit-hello-world`
3. **Compute platform**: `EC2/On-premises`
4. Click **Create application**

### 4.2 Create Deployment Group
1. In your new application, click **Create deployment group**
2. **Deployment group name**: `streamlit-deployment-group`
3. **Service role**: Select `CodeDeployServiceRole`
4. **Deployment type**: `In-place`
5. **Environment configuration**: Select **Amazon EC2 instances** (NOT On-premises)
6. **Tag group**: 
   - Click **Add tag group**
   - **Key**: `Name` (exactly as you tagged your EC2 instance)
   - **Value**: `streamlit-app-server` (exactly as you tagged your EC2 instance)
7. **Install AWS CodeDeploy Agent**: Select **Never** (we installed it via user data)
8. **Deployment configuration**: `CodeDeployDefault.AllAtOnce`
9. **Load balancer**: Uncheck "Enable load balancing"
10. Click **Create deployment group**

## Step 5: Create S3 Bucket for Pipeline Artifacts

1. Go to **S3 Console** → **Create bucket**
2. **Bucket name**: `your-name-codepipeline-artifacts-2025` (must be globally unique)
3. **Region**: Same region as your EC2 instance
4. Leave all other settings as default
5. Click **Create bucket**

## Step 6: Create CodePipeline

### 6.1 Create Pipeline
1. Go to **CodePipeline Console** → **Create pipeline**
2. **Pipeline name**: `streamlit-deployment-pipeline`
3. **Service role**: Select **New service role** (let AWS create it)
4. **Artifact store**: Select **Default location** or choose your S3 bucket
5. Click **Next**

### 6.2 Add Source Stage
1. **Source provider**: Select **GitHub (Version 2)** or **GitHub via app id**
2. **Connection**: Click **Connect to GitHub**
   - This will open GitHub authorization
   - Click **Install a new app**
   - Select your GitHub account
   - Choose **All repositories** or **Only select repositories** (select your repo)
   - Click **Install**
   - Back in AWS, click **Connect**
3. **Repository name**: Select your repository
4. **Branch name**: `main`
5. **Change detection options**: Leave checked
6. Click **Next**

### 6.3 Add Build Stage
1. Click **Skip build stage**
2. Confirm by clicking **Skip**

### 6.4 Add Deploy Stage
1. **Deploy provider**: **AWS CodeDeploy**
2. **Region**: Your AWS region
3. **Application name**: `streamlit-hello-world`
4. **Deployment group**: `streamlit-deployment-group`
5. Click **Next**

### 6.5 Review and Create
1. Review all settings
2. Click **Create pipeline**

The pipeline will start automatically and may fail the first time - this is normal as we're still setting up.

## Step 7: Verify Your Setup

### 7.1 Check EC2 Instance
1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Check that:
   - **State**: Running
   - **Status checks**: 2/2 checks passed
   - **IAM role**: EC2CodeDeployRole is attached
   - **Tags**: Name = streamlit-app-server

### 7.2 Check CodeDeploy Agent
SSH into your instance and check:
```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
sudo service codedeploy-agent status
```
Should show: "The AWS CodeDeploy agent is running"

### 7.3 Test the Pipeline
1. Make a small change to your `app.py` file locally
2. Commit and push:
```bash
git add .
git commit -m "Test deployment"
git push
```
3. Go to **CodePipeline Console** and watch your pipeline run

## Step 8: Access Your App

Once the pipeline completes successfully:

1. Get your EC2 public IP from the EC2 Console
2. Open your browser and go to: `http://YOUR_EC2_PUBLIC_IP:8501`
3. You should see your Streamlit app!

## Troubleshooting Common Issues

### Issue 1: "No instances found for deployment group"
**Cause**: Tag mismatch between EC2 instance and deployment group
**Solution**: 
1. Check your EC2 instance tags in EC2 Console
2. Update deployment group tags to match exactly (case-sensitive)

### Issue 2: CodeDeploy agent not running
**Solution**:
```bash
sudo service codedeploy-agent start
sudo service codedeploy-agent status
```

### Issue 3: Streamlit not starting
**Check logs**:
```bash
sudo cat /var/log/codedeploy-install.log
cat /home/ec2-user/streamlit.log
```

**Manual start**:
```bash
cd /home/ec2-user/streamlit-app
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
```

### Issue 4: Can't access from browser
**Check security group**: Ensure port 8501 is open to 0.0.0.0/0

## Important Notes

1. **Tags must match exactly** between EC2 instance and deployment group
2. **Use Amazon Linux 2023** for the EC2 instance
3. **Select "Amazon EC2 instances"** not "On-premises instances"
4. **Select "Never"** for CodeDeploy agent installation (we handle it via user data)
5. **Make sure port 8501 is open** in your security group

## What Each File Does

- **app.py**: Your Streamlit application
- **requirements.txt**: Python dependencies
- **appspec.yml**: Tells CodeDeploy how to deploy your app
- **ec2-user-data.sh**: Sets up your EC2 instance with CodeDeploy agent
- **scripts/install_dependencies.sh**: Installs Python packages
- **scripts/start_server.sh**: Starts your Streamlit app
- **scripts/stop_server.sh**: Stops your Streamlit app

Follow these steps exactly, and your Streamlit app should deploy successfully to EC2!
