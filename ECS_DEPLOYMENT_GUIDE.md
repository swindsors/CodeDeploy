# AWS ECS Deployment Guide for Streamlit Application

This guide provides comprehensive step-by-step instructions for deploying your Streamlit application using Amazon Elastic Container Service (ECS) with Fargate.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1: Create Dockerfile](#step-1-create-dockerfile)
3. [Step 2: Set up Amazon ECR Repository](#step-2-set-up-amazon-ecr-repository)
4. [Step 3: Build and Push Docker Image](#step-3-build-and-push-docker-image)
5. [Step 4: Create ECS Cluster](#step-4-create-ecs-cluster)
6. [Step 5: Create Task Definition](#step-5-create-task-definition)
7. [Step 6: Set up Application Load Balancer](#step-6-set-up-application-load-balancer)
8. [Step 7: Create ECS Service](#step-7-create-ecs-service)
9. [Step 8: Configure Auto Scaling](#step-8-configure-auto-scaling)
10. [Step 9: Set up CloudWatch Monitoring](#step-9-set-up-cloudwatch-monitoring)
11. [Step 10: Configure Custom Domain (Optional)](#step-10-configure-custom-domain-optional)
12. [Troubleshooting Guide](#troubleshooting-guide)

## Prerequisites

Before starting, ensure you have:
- AWS CLI installed and configured with appropriate permissions
- Docker installed on your local machine
- An AWS account with the following IAM permissions:
  - ECS Full Access
  - ECR Full Access
  - EC2 Full Access
  - IAM Role creation permissions
  - CloudWatch Logs permissions
  - Application Load Balancer permissions

### Required AWS CLI Configuration
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and output format
```

## Step 1: Create Dockerfile

Create a Dockerfile in your project root directory to containerize your Streamlit application.

**Why this step is important:** Docker containers ensure your application runs consistently across different environments and are required for ECS deployment.

```dockerfile
# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory in container
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port 8501 (Streamlit default port)
EXPOSE 8501

# Configure Streamlit to run on all interfaces
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0
ENV STREAMLIT_SERVER_PORT=8501

# Health check to ensure container is running properly
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health || exit 1

# Run Streamlit application
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
```

**Key Configuration Explanations:**
- `STREAMLIT_SERVER_ADDRESS=0.0.0.0`: Allows external connections to the container
- `--server.port=8501`: Standard Streamlit port
- Health check ensures ECS can monitor container health

## Step 2: Set up Amazon ECR Repository

Amazon Elastic Container Registry (ECR) will store your Docker images.

**Why ECR:** ECR integrates seamlessly with ECS and provides secure, scalable container image storage.

### Create ECR Repository
```bash
# Create ECR repository
aws ecr create-repository --repository-name streamlit-app --region us-east-1

# Note the repositoryUri from the output - you'll need this later
```

### Get ECR Login Token
```bash
# Get login token for Docker
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**Replace `<your-account-id>`** with your actual AWS account ID.

## Step 3: Build and Push Docker Image

Build your Docker image locally and push it to ECR.

### Build Docker Image
```bash
# Build the Docker image
docker build -t streamlit-app .

# Test the image locally (optional but recommended)
docker run -p 8501:8501 streamlit-app
# Visit http://localhost:8501 to test your app
```

### Tag and Push to ECR
```bash
# Tag the image for ECR
docker tag streamlit-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/streamlit-app:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/streamlit-app:latest
```

**Important:** Replace `<your-account-id>` with your AWS account ID throughout this guide.

## Step 4: Create ECS Cluster

An ECS cluster is a logical grouping of compute resources.

**Why Fargate:** We'll use Fargate for serverless container management - no EC2 instances to manage.

### Using AWS Console:
1. Navigate to ECS Console
2. Click "Create Cluster"
3. Choose "Networking only" (Fargate)
4. Cluster name: `streamlit-cluster`
5. Create VPC: Check this option for new deployments
6. Click "Create"

### Using AWS CLI:
```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name streamlit-cluster --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1
```

## Step 5: Create Task Definition

A task definition is like a blueprint that tells ECS how to run your container.

### Create Task Definition JSON File

Create `task-definition.json`:

```json
{
  "family": "streamlit-app-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "streamlit-container",
      "image": "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/streamlit-app:latest",
      "portMappings": [
        {
          "containerPort": 8501,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/streamlit-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:8501/_stcore/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### Create Required IAM Roles

**ECS Task Execution Role:**
```bash
# Create trust policy for task execution role
cat > task-execution-assume-role-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role-policy.json

# Attach the managed policy
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

**ECS Task Role (for application permissions):**
```bash
# Create task role
aws iam create-role --role-name ecsTaskRole --assume-role-policy-document file://task-execution-assume-role-policy.json
```

### Create CloudWatch Log Group
```bash
# Create log group for container logs
aws logs create-log-group --log-group-name /ecs/streamlit-app --region us-east-1
```

### Register Task Definition
```bash
# Register the task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

**Resource Allocation Explanation:**
- **CPU: 256** - 0.25 vCPU (sufficient for a simple Streamlit app)
- **Memory: 512 MB** - Adequate for Streamlit with basic functionality
- Scale up if your app requires more resources

## Step 6: Set up Application Load Balancer

An Application Load Balancer (ALB) distributes incoming traffic across your containers.

**Why ALB:** Provides high availability, health checks, and SSL termination capabilities.

### Create Security Groups

**ALB Security Group:**
```bash
# Get your VPC ID (replace with your actual VPC ID)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)

# Create ALB security group
aws ec2 create-security-group --group-name streamlit-alb-sg --description "Security group for Streamlit ALB" --vpc-id $VPC_ID

# Get the security group ID
ALB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=streamlit-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

# Allow HTTPS traffic
aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
```

**ECS Service Security Group:**
```bash
# Create ECS service security group
aws ec2 create-security-group --group-name streamlit-ecs-sg --description "Security group for Streamlit ECS service" --vpc-id $VPC_ID

# Get the security group ID
ECS_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=streamlit-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow traffic from ALB to ECS service
aws ec2 authorize-security-group-ingress --group-id $ECS_SG_ID --protocol tcp --port 8501 --source-group $ALB_SG_ID
```

### Create Application Load Balancer
```bash
# Get subnet IDs (you need at least 2 subnets in different AZs)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text)

# Create ALB
aws elbv2 create-load-balancer --name streamlit-alb --subnets $SUBNET_IDS --security-groups $ALB_SG_ID --scheme internet-facing --type application
```

### Create Target Group
```bash
# Create target group
aws elbv2 create-target-group --name streamlit-targets --protocol HTTP --port 8501 --vpc-id $VPC_ID --target-type ip --health-check-path /_stcore/health --health-check-interval-seconds 30 --health-check-timeout-seconds 5 --healthy-threshold-count 2 --unhealthy-threshold-count 3
```

### Create Listener
```bash
# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers --names streamlit-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Get Target Group ARN
TG_ARN=$(aws elbv2 describe-target-groups --names streamlit-targets --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create listener
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

## Step 7: Create ECS Service

An ECS service ensures your desired number of tasks are running and healthy.

### Create Service Definition

Create `service-definition.json`:

```json
{
  "serviceName": "streamlit-service",
  "cluster": "streamlit-cluster",
  "taskDefinition": "streamlit-app-task",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"],
      "securityGroups": ["sg-xxxxxxxxx"],
      "assignPublicIp": "ENABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/streamlit-targets/xxxxxxxxx",
      "containerName": "streamlit-container",
      "containerPort": 8501
    }
  ],
  "healthCheckGracePeriodSeconds": 300
}
```

**Update the following values:**
- Replace subnet IDs with your actual subnet IDs
- Replace security group ID with your ECS security group ID
- Replace target group ARN with your actual target group ARN

### Create the Service
```bash
# Create ECS service
aws ecs create-service --cli-input-json file://service-definition.json
```

**Service Configuration Explanation:**
- **desiredCount: 2** - Runs 2 instances for high availability
- **healthCheckGracePeriodSeconds: 300** - Gives containers time to start before health checks begin

## Step 8: Configure Auto Scaling

Auto scaling automatically adjusts the number of running tasks based on demand.

### Create Auto Scaling Target
```bash
# Register scalable target
aws application-autoscaling register-scalable-target --service-namespace ecs --resource-id service/streamlit-cluster/streamlit-service --scalable-dimension ecs:service:DesiredCount --min-capacity 1 --max-capacity 10
```

### Create Scaling Policies

**Scale Up Policy:**
```bash
# Create scale up policy
aws application-autoscaling put-scaling-policy --service-namespace ecs --resource-id service/streamlit-cluster/streamlit-service --scalable-dimension ecs:service:DesiredCount --policy-name streamlit-scale-up --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://scale-up-policy.json
```

Create `scale-up-policy.json`:
```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 300,
  "ScaleInCooldown": 300
}
```

**Scaling Policy Explanation:**
- **TargetValue: 70.0** - Maintains average CPU utilization at 70%
- **ScaleOutCooldown: 300** - Waits 5 minutes before scaling out again
- **ScaleInCooldown: 300** - Waits 5 minutes before scaling in again

## Step 9: Set up CloudWatch Monitoring

CloudWatch provides monitoring and alerting for your ECS service.

### Create CloudWatch Dashboard
```bash
# Create dashboard configuration
cat > dashboard-config.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "streamlit-service", "ClusterName", "streamlit-cluster"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/streamlit-alb/xxxxxxxxx"],
          [".", "TargetResponseTime", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Load Balancer Metrics"
      }
    }
  ]
}
EOF

# Create dashboard
aws cloudwatch put-dashboard --dashboard-name "Streamlit-App-Dashboard" --dashboard-body file://dashboard-config.json
```

### Create CloudWatch Alarms
```bash
# High CPU alarm
aws cloudwatch put-metric-alarm --alarm-name "Streamlit-High-CPU" --alarm-description "High CPU utilization" --metric-name CPUUtilization --namespace AWS/ECS --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=ServiceName,Value=streamlit-service Name=ClusterName,Value=streamlit-cluster --evaluation-periods 2

# High memory alarm
aws cloudwatch put-metric-alarm --alarm-name "Streamlit-High-Memory" --alarm-description "High memory utilization" --metric-name MemoryUtilization --namespace AWS/ECS --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=ServiceName,Value=streamlit-service Name=ClusterName,Value=streamlit-cluster --evaluation-periods 2
```

## Step 10: Configure Custom Domain (Optional)

If you have a custom domain, you can configure it with your load balancer.

### Prerequisites:
- A registered domain name
- Route 53 hosted zone (or external DNS provider)
- SSL certificate from AWS Certificate Manager

### Request SSL Certificate
```bash
# Request certificate (replace with your domain)
aws acm request-certificate --domain-name yourdomain.com --subject-alternative-names www.yourdomain.com --validation-method DNS --region us-east-1
```

### Update Load Balancer Listener for HTTPS
```bash
# Create HTTPS listener (after certificate is validated)
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTPS --port 443 --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxxx --default-actions Type=forward,TargetGroupArn=$TG_ARN
```

### Create Route 53 Record
```bash
# Create Route 53 record (replace with your hosted zone ID and domain)
aws route53 change-resource-record-sets --hosted-zone-id Z123456789 --change-batch file://route53-change.json
```

## Deployment Verification

After completing all steps, verify your deployment:

1. **Check ECS Service Status:**
   ```bash
   aws ecs describe-services --cluster streamlit-cluster --services streamlit-service
   ```

2. **Check Task Health:**
   ```bash
   aws ecs list-tasks --cluster streamlit-cluster --service-name streamlit-service
   aws ecs describe-tasks --cluster streamlit-cluster --tasks <task-arn>
   ```

3. **Test Load Balancer:**
   ```bash
   # Get ALB DNS name
   aws elbv2 describe-load-balancers --names streamlit-alb --query 'LoadBalancers[0].DNSName' --output text
   ```

4. **Access Your Application:**
   - Navigate to the ALB DNS name in your browser
   - You should see your Streamlit application running

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Container Fails to Start

**Symptoms:**
- Tasks keep stopping and restarting
- Service shows "PENDING" status for extended periods

**Diagnosis:**
```bash
# Check task logs
aws logs get-log-events --log-group-name /ecs/streamlit-app --log-stream-name ecs/streamlit-container/<task-id>

# Check task definition
aws ecs describe-task-definition --task-definition streamlit-app-task
```

**Common Causes & Solutions:**

**a) Insufficient Resources:**
- **Problem:** Container requires more CPU/memory than allocated
- **Solution:** Update task definition with higher CPU/memory values
```bash
# Update task definition with more resources
# Edit task-definition.json: increase "cpu": "512", "memory": "1024"
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster streamlit-cluster --service streamlit-service --task-definition streamlit-app-task
```

**b) Image Pull Errors:**
- **Problem:** ECS cannot pull image from ECR
- **Solution:** Check ECR permissions and image URI
```bash
# Verify image exists
aws ecr describe-images --repository-name streamlit-app

# Check task execution role permissions
aws iam get-role-policy --role-name ecsTaskExecutionRole --policy-name ECRAccessPolicy
```

**c) Port Configuration Issues:**
- **Problem:** Application not listening on expected port
- **Solution:** Verify Streamlit configuration
```dockerfile
# Ensure Dockerfile has correct port configuration
EXPOSE 8501
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
```

#### 2. Load Balancer Health Check Failures

**Symptoms:**
- Targets showing as "unhealthy" in target group
- 502/503 errors when accessing application

**Diagnosis:**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# Check ALB access logs (if enabled)
aws s3 ls s3://your-alb-logs-bucket/
```

**Solutions:**

**a) Health Check Path Issues:**
- **Problem:** Health check path returns 404
- **Solution:** Update target group health check path
```bash
# Update health check path
aws elbv2 modify-target-group --target-group-arn $TG_ARN --health-check-path /_stcore/health
```

**b) Security Group Configuration:**
- **Problem:** ALB cannot reach ECS tasks
- **Solution:** Verify security group rules
```bash
# Check ECS security group allows traffic from ALB
aws ec2 describe-security-groups --group-ids $ECS_SG_ID
```

**c) Container Health Check Failures:**
- **Problem:** Container health checks failing
- **Solution:** Adjust health check parameters
```json
{
  "healthCheck": {
    "command": ["CMD-SHELL", "curl -f http://localhost:8501/_stcore/health || exit 1"],
    "interval": 30,
    "timeout": 10,
    "retries": 5,
    "startPeriod": 120
  }
}
```

#### 3. Service Discovery Issues

**Symptoms:**
- Tasks start but cannot communicate with each other
- External services cannot reach the application

**Solutions:**

**a) VPC Configuration:**
- **Problem:** Incorrect subnet or VPC configuration
- **Solution:** Verify network configuration
```bash
# Check VPC and subnet configuration
aws ec2 describe-vpcs --vpc-ids $VPC_ID
aws ec2 describe-subnets --subnet-ids $SUBNET_ID
```

**b) DNS Resolution:**
- **Problem:** Service discovery not working
- **Solution:** Enable service discovery
```bash
# Create service discovery namespace
aws servicediscovery create-private-dns-namespace --name streamlit.local --vpc $VPC_ID
```

#### 4. Auto Scaling Issues

**Symptoms:**
- Service not scaling up/down as expected
- Scaling events not triggering

**Diagnosis:**
```bash
# Check scaling activities
aws application-autoscaling describe-scaling-activities --service-namespace ecs --resource-id service/streamlit-cluster/streamlit-service

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=streamlit-service Name=ClusterName,Value=streamlit-cluster --start-time 2023-01-01T00:00:00Z --end-time 2023-01-01T23:59:59Z --period 300 --statistics Average
```

**Solutions:**

**a) Metric Thresholds:**
- **Problem:** Scaling thresholds too high/low
- **Solution:** Adjust scaling policy
```bash
# Update scaling policy with new target value
aws application-autoscaling put-scaling-policy --service-namespace ecs --resource-id service/streamlit-cluster/streamlit-service --scalable-dimension ecs:service:DesiredCount --policy-name streamlit-scale-up --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration TargetValue=60.0,PredefinedMetricSpecification='{PredefinedMetricType=ECSServiceAverageCPUUtilization}'
```

**b) Cooldown Periods:**
- **Problem:** Scaling happening too frequently
- **Solution:** Increase cooldown periods
```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 600,
  "ScaleInCooldown": 600
}
```

#### 5. Performance Issues

**Symptoms:**
- Slow response times
- High CPU/memory utilization
- Frequent container restarts

**Solutions:**

**a) Resource Optimization:**
```bash
# Monitor resource usage
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=streamlit-service --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average,Maximum
```

**b) Application Optimization:**
- Enable Streamlit caching for better performance
- Optimize Docker image size
- Use multi-stage builds

```dockerfile
# Multi-stage build example
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8501
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]
```

#### 6. Logging and Monitoring Issues

**Symptoms:**
- Missing logs in CloudWatch
- Monitoring dashboards showing no data

**Solutions:**

**a) Log Configuration:**
```bash
# Verify log group exists
aws logs describe-log-groups --log-group-name-prefix /ecs/streamlit-app

# Check log streams
aws logs describe-log-streams --log-group-name /ecs/streamlit-app
```

**b) IAM Permissions:**
```bash
# Verify task execution role has CloudWatch permissions
aws iam list-attached-role-policies --role-name ecsTaskExecutionRole
```

### Emergency Procedures

#### Rolling Back Deployment
```bash
# List task definition revisions
aws ecs list-task-definitions --family-prefix streamlit-app-task

# Update service to previous task definition
aws ecs update-service --cluster streamlit-cluster --service streamlit-service --task-definition streamlit-app-task:1
```

#### Scaling Down in Emergency
```bash
# Immediately scale down to 0 tasks
aws ecs update-service --cluster streamlit-cluster --service streamlit-service --desired-count 0

# Scale back up when ready
aws ecs update-service --cluster streamlit-cluster --service streamlit-service --desired-count 2
```

#### Accessing Container for Debugging
```bash
# Enable ECS Exec for debugging
aws ecs update-service --cluster streamlit-cluster --service streamlit-service --enable-execute-command

# Execute command in running container
aws ecs execute-command --cluster streamlit-cluster --task <task-arn> --container streamlit-container --interactive --command "/bin/bash"
```

### Monitoring Commands

#### Check Overall Service Health
```bash
#!/bin/bash
# health-check.sh - Quick health check script

echo "=== ECS Service Status ==="
aws ecs describe-services --cluster streamlit-cluster --services streamlit-service --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}'

echo "=== Target Group Health ==="
aws elbv2 describe-target-health --target-group-arn $TG_ARN --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}'

echo "=== Recent CloudWatch Alarms ==="
aws cloudwatch describe-alarms --state-value ALARM --query 'MetricAlarms[?contains(AlarmName, `Streamlit`)].{Name:AlarmName,State:StateValue,Reason:StateReason}'
```

#### Performance Monitoring
```bash
#!/bin/bash
# performance-check.sh - Performance monitoring script

echo "=== CPU Utilization (Last Hour) ==="
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=streamlit-service Name=ClusterName,Value=streamlit-cluster --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average,Maximum --query 'Datapoints[*].{Time:Timestamp,Avg:Average,Max:Maximum}' --output table

echo "=== Memory Utilization (Last Hour) ==="
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization --dimensions Name=ServiceName,Value=streamlit-service Name=ClusterName,Value=streamlit-cluster --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average,Maximum --query 'Datapoints[*].{Time:Timestamp,Avg:Average,Max:Maximum}' --output table
```

## Cost Optimization Tips

1. **Right-size your resources:** Start with smaller CPU/memory allocations and scale up as needed
2. **Use Spot instances:** For non-critical workloads, consider Fargate Spot
3. **Implement proper auto-scaling:** Avoid over-provisioning resources
4. **Monitor and optimize:** Regularly review CloudWatch metrics and costs
5. **Use reserved capacity:** For predictable workloads, consider Savings Plans

## Security Best Practices

1. **Use least privilege IAM roles**
2. **Enable VPC Flow Logs**
3. **Implement WAF for additional protection**
4. **Use secrets management for sensitive data**
5. **Enable container insights for security monitoring**
6. **Regularly update base images and dependencies**

## Conclusion

This guide provides a comprehensive approach to deploying your Streamlit application on AWS ECS. The containerized approach offers scalability, reliability, and easier management compared to traditional EC2 deployments.

Key benefits of this ECS deployment:
- **High Availability:** Multiple availability zones and auto-scaling ensure your application stays online
- **Scalability:** Automatic scaling based on demand without manual intervention
- **Cost Efficiency:** Pay only for the resources you use with Fargate
- **Security:** VPC isolation, security groups, and IAM roles provide robust security
- **Monitoring:** Comprehensive CloudWatch integration for observability
- **Maintenance-Free:** No server management required with Fargate

## Next Steps

After successful deployment, consider these enhancements:

1. **CI/CD Pipeline:** Set up automated deployments using AWS CodePipeline
2. **Blue/Green Deployments:** Implement zero-downtime deployments
3. **Multi-Region Setup:** Deploy across multiple regions for disaster recovery
4. **Performance Optimization:** Fine-tune resource allocation based on usage patterns
5. **Advanced Monitoring:** Implement custom metrics and detailed application monitoring

## Support and Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)

Remember to regularly review your deployment for security updates, cost optimization opportunities, and performance improvements.
