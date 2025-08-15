# Streamlit Hello World App with AWS CodePipeline Deployment

This repository contains a simple Streamlit "Hello World" application that can be deployed to an EC2 instance using AWS CodePipeline and CodeDeploy.

## Project Structure

```
.
├── app.py                      # Main Streamlit application
├── requirements.txt            # Python dependencies
├── appspec.yml                # CodeDeploy application specification
├── ec2-user-data.sh           # EC2 instance initialization script
├── scripts/
│   ├── install_dependencies.sh # Install Python dependencies
│   ├── start_server.sh         # Start Streamlit server
│   └── stop_server.sh          # Stop Streamlit server
└── README.md                   # This file
```

## Step-by-Step Setup Instructions

### 1. Prerequisites

- AWS Account with appropriate permissions
- GitHub account
- AWS CLI installed and configured (optional but recommended)

### 2. Push Code to GitHub

1. Create a new repository on GitHub
2. Clone this repository or copy all files to your local project
3. Push the code to your GitHub repository:

```bash
git init
git add .
git commit -m "Initial commit: Streamlit app with CodeDeploy setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

### 3. Create IAM Roles

#### A. CodeDeploy Service Role

1. Go to IAM Console → Roles → Create Role
2. Select "AWS Service" → "CodeDeploy"
3. Select "CodeDeploy" use case
4. Attach policy: `AWSCodeDeployRole`
5. Name: `CodeDeployServiceRole`

#### B. EC2 Instance Role

1. Go to IAM Console → Roles → Create Role
2. Select "AWS Service" → "EC2"
3. Attach policies:
   - `AmazonEC2RoleforAWSCodeDeploy`
   - `CloudWatchAgentServerPolicy` (optional, for logging)
4. Name: `EC2CodeDeployRole`

#### C. CodePipeline Service Role

**Option 1: Let CodePipeline create the role automatically (Recommended)**
- When creating the CodePipeline in step 9, choose "New service role" and let AWS create it automatically with the necessary permissions.

**Option 2: Create the role manually**
1. Go to IAM Console → Roles → Create Role
2. Select "AWS Service" → Find and select "CodePipeline" from the list
3. AWS will automatically attach the `AWSCodePipelineServiceRole` policy
4. Name: `CodePipelineServiceRole`
5. After creation, you may need to add additional permissions for S3 and CodeDeploy by attaching these policies:
   - `AWSCodeDeployRole` (for CodeDeploy integration)
   - Custom inline policy for S3 access to your artifacts bucket

**Note**: If you encounter permission issues, you can add this inline policy to the CodePipeline service role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketVersioning",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-codepipeline-artifacts-bucket",
                "arn:aws:s3:::your-codepipeline-artifacts-bucket/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*"
        }
    ]
}
```

### 4. Launch EC2 Instance

1. Go to EC2 Console → Launch Instance
2. Choose Amazon Linux 2 AMI
3. Select instance type (t2.micro for testing)
4. Configure Instance Details:
   - IAM Role: Select `EC2CodeDeployRole`
   - User Data: Copy and paste the contents of `ec2-user-data.sh`
5. Add Storage: Default settings are fine
6. Configure Security Group:
   - Add rule: Type: Custom TCP, Port: 8501, Source: 0.0.0.0/0 (for Streamlit)
   - Add rule: Type: SSH, Port: 22, Source: Your IP
7. Launch with your key pair

### 5. Create CodeDeploy Application

1. Go to CodeDeploy Console → Applications → Create Application
2. Application name: `streamlit-hello-world`
3. Compute platform: `EC2/On-premises`

### 6. Create Deployment Group

1. In your CodeDeploy application → Create Deployment Group
2. Deployment group name: `streamlit-deployment-group`
3. Service role: Select `CodeDeployServiceRole`
4. Deployment type: `In-place`
5. Environment configuration: **Amazon EC2 instances** (NOT "On-premises instances")
6. **Tag group configuration (CRITICAL):**
   - Click "Add tag group"
   - **Key:** `Name` (or any tag key you used on your EC2 instance)
   - **Value:** The exact value of the tag on your EC2 instance
   - **Example:** If your EC2 instance has tag `Name = streamlit-server`, use:
     - Key: `Name`
     - Value: `streamlit-server`
   
   **To find your EC2 instance tags:**
   - Go to EC2 Console → Instances
   - Select your instance
   - Look at the "Tags" tab
   - Use the exact Key and Value (case-sensitive)
7. Deployment configuration: `CodeDeployDefault.AllAtOnce`
8. Load balancer: Uncheck "Enable load balancing"

**Important:** The tags in the deployment group must EXACTLY match the tags on your EC2 instance (case-sensitive).

### 7. Create S3 Bucket for Artifacts

1. Go to S3 Console → Create Bucket
2. Bucket name: `your-codepipeline-artifacts-bucket` (must be globally unique)
3. Region: Same as your other resources
4. Keep default settings and create

### 8. Set up GitHub Connection (for CodePipeline)

**Method 1: Create Connection During Pipeline Setup (Recommended)**
1. When creating your pipeline in step 9, you can create the GitHub connection directly
2. In the source stage, select "GitHub (Version 2)"
3. Click "Connect to GitHub" 
4. This will open the GitHub authorization flow (see steps below)

**Method 2: Create Connection Beforehand**
1. Go to CodePipeline Console → Settings → Connections
2. Click "Create connection"
3. Provider: Select "GitHub"
4. Connection name: `github-connection`
5. Click "Connect to GitHub"

**GitHub Authorization Process (for both methods):**

1. **Install AWS Connector App:**
   - You'll be redirected to GitHub
   - Click "Install a new app" or "Configure" if you've used it before
   - Select your GitHub account or organization
   - Choose repositories:
     - **"All repositories"** (easier, gives access to all your repos)
     - **"Only select repositories"** (more secure, select just your Streamlit repo)
   - Click "Install" or "Save"

2. **Complete Connection:**
   - You'll be redirected back to AWS
   - Click "Connect" to finalize the connection
   - The connection status should show as "Available"

**Troubleshooting GitHub Authorization:**

- **"Pending" connection status:** 
  - Go back to GitHub → Settings → Applications → Installed GitHub Apps
  - Find "AWS Connector for GitHub" and ensure it's properly configured
  
- **Permission denied errors:**
  - Make sure you have admin access to the GitHub repository
  - Check that the AWS Connector app has access to your specific repository

- **Connection not found during pipeline creation:**
  - Refresh the CodePipeline page
  - The connection might take a few minutes to appear in the dropdown

**Important Notes:**
- You only need to do this authorization once per AWS account
- The same connection can be used for multiple pipelines
- GitHub will send you email notifications about the AWS Connector app installation

### 9. Create CodePipeline

1. Go to CodePipeline Console → Create Pipeline
2. **Pipeline settings:**
   - Pipeline name: `streamlit-deployment-pipeline`
   - Service role: Choose "New service role" (recommended) or select existing `CodePipelineServiceRole`
   - Artifact store: Choose "Default location" or select your custom S3 bucket
   - Click "Next"

3. **Add source stage:**
   - Source provider: **GitHub (Version 2)** or **"GitHub via app id"** (same thing, different display names)
   - Connection: Select your GitHub connection (created in step 8)
   - Repository name: Your repository name (e.g., `YOUR_USERNAME/YOUR_REPO_NAME`)
   - Branch name: `main`
   - Change detection options: Leave "Start the pipeline on source code change" checked
   - Output artifacts: `SourceOutput` (default name)
   - Click "Next"

4. **Add build stage:**
   - **Skip this step** - Click "Skip build stage" since we don't need to build/compile anything for this Python app
   - Confirm by clicking "Skip"

5. **Add deploy stage:**
   - Deploy provider: **AWS CodeDeploy**
   - Region: Your AWS region (e.g., `us-east-1`)
   - Application name: `streamlit-hello-world` (created in step 5)
   - Deployment group: `streamlit-deployment-group` (created in step 6)
   - Input artifacts: `SourceOutput`
   - Click "Next"

6. **Review and create:**
   - Review all settings
   - Click "Create pipeline"

**Note:** We're not using ECR (Elastic Container Registry) because this setup deploys Python code directly to EC2, not Docker containers. ECR would be used if you were containerizing your Streamlit app with Docker and deploying to ECS or EKS.

### 10. Test the Deployment

1. Make a small change to your `app.py` file
2. Commit and push to GitHub:
```bash
git add .
git commit -m "Test deployment"
git push
```
3. Watch the pipeline execute in CodePipeline Console
4. Once complete, access your app at: `http://YOUR_EC2_PUBLIC_IP:8501`

## Troubleshooting

### Common Issues:

1. **CodeDeploy agent not running**: SSH into EC2 and run:
```bash
sudo service codedeploy-agent status
sudo service codedeploy-agent start
```

2. **Permission issues**: Ensure IAM roles have correct policies attached

3. **Security group**: Make sure port 8501 is open in your EC2 security group

4. **Streamlit not starting**: Check logs:
```bash
tail -f /home/ec2-user/streamlit.log
```

5. **CodeDeploy deployment fails**: Check deployment logs in CodeDeploy Console

### Useful Commands:

```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Check CodeDeploy agent status
sudo service codedeploy-agent status

# Check if Streamlit is running
ps aux | grep streamlit

# View Streamlit logs
tail -f /home/ec2-user/streamlit.log

# Manually start Streamlit (for testing)
cd /home/ec2-user/streamlit-app
python3 -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
```

## Security Considerations

- The security group allows access from anywhere (0.0.0.0/0) on port 8501. In production, restrict this to specific IP ranges.
- Consider using HTTPS with a load balancer and SSL certificate.
- Regularly update your EC2 instance and dependencies.

## Cost Optimization

- Use t2.micro or t3.micro instances for development/testing
- Stop EC2 instances when not in use
- Consider using AWS Lambda with Streamlit for serverless deployment (requires additional setup)

## Next Steps

- Add automated testing to your pipeline
- Implement blue/green deployments
- Add monitoring and alerting
- Set up a custom domain with Route 53
- Implement HTTPS with Application Load Balancer
