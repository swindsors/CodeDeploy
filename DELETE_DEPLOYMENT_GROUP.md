# How to Delete a CodeDeploy Deployment Group

## Method 1: AWS Console (Recommended)

### Step 1: Navigate to CodeDeploy
1. Go to **AWS Console** → **CodeDeploy**
2. Click **Applications** in the left sidebar

### Step 2: Find Your Application
1. Click on your application name (e.g., `streamlit-hello-world`)
2. You'll see a list of deployment groups

### Step 3: Delete the Deployment Group
1. Find the deployment group you want to delete (e.g., `streamlit-deployment-group`)
2. Click on the deployment group name
3. Click **Actions** → **Delete deployment group**
4. Type the deployment group name to confirm
5. Click **Delete**

## Method 2: AWS CLI

If you have AWS CLI configured:

```bash
# Delete a deployment group
aws deploy delete-deployment-group \
  --application-name streamlit-hello-world \
  --deployment-group-name streamlit-deployment-group
```

## Important Notes

### ⚠️ Before Deleting
- **Stop any active deployments** first
- **Update your CodePipeline** if it references this deployment group
- **Consider creating a new deployment group** before deleting the old one

### Check for Active Deployments
1. In the deployment group, click **Deployments** tab
2. If any deployments show "In Progress", wait for them to complete or stop them:
   - Click on the deployment ID
   - Click **Stop deployment** if needed

### Update CodePipeline After Deletion
If your CodePipeline references the deleted deployment group:

1. Go to **CodePipeline Console**
2. Click your pipeline → **Edit**
3. Click **Edit** on the Deploy stage
4. Update the **Deployment group** to a new one
5. Click **Done** → **Save**

## Creating a New Deployment Group

If you need to create a replacement:

### Step 1: Create New Deployment Group
1. In your CodeDeploy application, click **Create deployment group**
2. **Deployment group name**: `streamlit-deployment-group-v2`
3. **Service role**: Select your CodeDeploy service role
4. **Deployment type**: `In-place`
5. **Environment configuration**: `Amazon EC2 instances`
6. **Tag group**: 
   - **Key**: `Name`
   - **Value**: `streamlit-app-server` (match your EC2 tags exactly)
7. **Install AWS CodeDeploy Agent**: `Never`
8. **Deployment configuration**: `CodeDeployDefault.AllAtOnce`
9. Click **Create deployment group**

### Step 2: Update CodePipeline
1. Go to **CodePipeline** → Your pipeline → **Edit**
2. Click **Edit** on the Deploy stage
3. **Deployment group**: Select your new deployment group
4. Click **Done** → **Save**

## Troubleshooting

### "Cannot delete deployment group with active deployments"
1. Go to the deployment group
2. Click **Deployments** tab
3. Stop any active deployments
4. Wait for them to complete
5. Try deleting again

### "Deployment group is referenced by a pipeline"
1. Update your CodePipeline first (see steps above)
2. Then delete the deployment group

### "Access denied"
Make sure your IAM user/role has these permissions:
- `codedeploy:DeleteDeploymentGroup`
- `codedeploy:GetDeploymentGroup`
- `codedeploy:ListDeploymentGroups`

## Why You Might Want to Delete

Common reasons to delete a deployment group:
- **Wrong configuration** (tags, service role, etc.)
- **Testing different settings**
- **Cleaning up unused resources**
- **Starting fresh** with a new setup

## Alternative: Modify Instead of Delete

Instead of deleting, you can modify the deployment group:
1. Click on the deployment group name
2. Click **Edit**
3. Update the configuration as needed
4. Click **Save changes**

This is often safer than deleting and recreating.
