# Fix CodeConnections Permission Error

## Problem
You're getting this error:
```
Unable to use Connection: arn:aws:codeconnections:us-east-1:804711833877:connection/21edde58-9108-4365-9c7c-de569ad473d8. The provided role does not have sufficient permissions.
```

This means your CodePipeline service role doesn't have permission to use AWS CodeConnections to access GitHub.

## Solution: Update CodePipeline Service Role Permissions

### Step 1: Find Your CodePipeline Service Role
1. Go to **CodePipeline Console**
2. Click on your pipeline: `streamlit-deployment-pipeline`
3. Click **Settings** tab
4. Note the **Service role ARN** (it will look like `arn:aws:iam::ACCOUNT:role/service-role/AWSCodePipelineServiceRole-us-east-1-XXXXX`)
5. Copy the role name (the part after the last `/`)

### Step 2: Add Required Permissions to the Role
1. Go to **IAM Console** → **Roles**
2. Search for your CodePipeline service role (from Step 1)
3. Click on the role name
4. Click **Add permissions** → **Attach policies**
5. Search for and attach these policies:
   - `AWSCodeStarConnectionsReadOnlyAccess`
   - `AWSCodeStarConnectionsUserAccess`
6. Click **Add permissions**

### Step 3: Alternative - Create Custom Policy (If above policies don't work)
If the managed policies don't work, create a custom policy:

1. In the IAM role, click **Add permissions** → **Create inline policy**
2. Click **JSON** tab
3. Paste this policy:

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

4. Click **Next**
5. Policy name: `CodeConnectionsAccess`
6. Click **Create policy**

### Step 4: Verify the Connection Status
1. Go to **Developer Tools** → **Connections** in AWS Console
2. Find your connection (ID: `21edde58-9108-4365-9c7c-de569ad473d8`)
3. Check its status:
   - If it shows **Available** - you're good to go
   - If it shows **Pending** - click on it and complete the authorization

### Step 5: Test Your Pipeline
1. Go back to **CodePipeline Console**
2. Click on your pipeline
3. Click **Release change** to trigger a new run
4. The pipeline should now work without the permission error

## Alternative Solution: Recreate the GitHub Connection

If the above doesn't work, you may need to recreate the GitHub connection:

### Step 1: Delete Old Connection
1. Go to **Developer Tools** → **Connections**
2. Find your connection and delete it

### Step 2: Update Your Pipeline Source
1. Go to **CodePipeline Console**
2. Click your pipeline → **Edit**
3. Click **Edit** on the Source stage
4. Click **Connect to GitHub** again
5. Create a new connection
6. Select your repository
7. Save the changes

### Step 3: Update Role Permissions
Follow Steps 2-3 from the main solution above with the new connection ARN.

## Quick Fix Command (If you have AWS CLI)

If you have AWS CLI configured, you can add the permissions quickly:

```bash
# Replace ROLE_NAME with your actual CodePipeline service role name
aws iam attach-role-policy \
  --role-name YOUR_CODEPIPELINE_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeStarConnectionsReadOnlyAccess

aws iam attach-role-policy \
  --role-name YOUR_CODEPIPELINE_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeStarConnectionsUserAccess
```

## What This Fixes

- Allows CodePipeline to use AWS CodeConnections to access your GitHub repository
- Enables automatic triggering when you push code to GitHub
- Fixes the "insufficient permissions" error

After applying these changes, your pipeline should work correctly and automatically deploy your Streamlit app when you push changes to GitHub.
