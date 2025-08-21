# GitHub Connection Information for AWS CodePipeline

## You DON'T Need a GitHub Token

When using **AWS CodeConnections** (the modern way), you don't need to create a GitHub personal access token. AWS handles the authentication through OAuth.

## Connection Names and IDs

Based on your error message, your connection details are:
- **Connection ARN**: `arn:aws:codeconnections:us-east-1:804711833877:connection/21edde58-9108-4365-9c7c-de569ad473d8`
- **Connection ID**: `21edde58-9108-4365-9c7c-de569ad473d8`

## How to Find Your Connection Name

### Method 1: AWS Console
1. Go to **AWS Console** → **Developer Tools** → **Connections**
2. You'll see your connection listed with:
   - **Connection name** (you chose this when creating it)
   - **Provider**: GitHub
   - **Status**: Should be "Available"

### Method 2: Through CodePipeline
1. Go to **CodePipeline Console**
2. Click your pipeline name
3. Click **Edit**
4. In the Source stage, you'll see the connection name

## Common Connection Names

People typically name their GitHub connections something like:
- `github-connection`
- `my-github-connection`
- `streamlit-github-connection`
- `github-oauth-connection`

## If You Need to Create a New Connection

If your current connection isn't working, here's how to create a new one:

### Step 1: Create New Connection
1. Go to **Developer Tools** → **Connections** → **Create connection**
2. **Provider**: GitHub
3. **Connection name**: Choose a name like `github-connection-2025`
4. Click **Connect to GitHub**
5. **Install a new app** or **Use an existing GitHub app**
6. Authorize AWS to access your repositories
7. Click **Connect**

### Step 2: Update Your Pipeline
1. Go to **CodePipeline** → Your pipeline → **Edit**
2. Click **Edit** on the Source stage
3. **Connection**: Select your new connection
4. **Repository name**: Select your repository
5. **Branch**: `main`
6. Click **Done** → **Save**

## Alternative: Use GitHub (Version 1) with Token

If you prefer to use a GitHub personal access token instead:

### Step 1: Create GitHub Token
1. Go to **GitHub.com** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. **Note**: `AWS CodePipeline Access`
4. **Expiration**: Choose your preference
5. **Scopes**: Select `repo` (full control of private repositories)
6. Click **Generate token**
7. **Copy the token immediately** (you won't see it again)

### Step 2: Update Pipeline Source
1. Go to **CodePipeline** → Your pipeline → **Edit**
2. Click **Edit** on the Source stage
3. **Source provider**: Change to **GitHub (Version 1)**
4. **Repository**: `your-username/your-repo-name`
5. **Branch**: `main`
6. **GitHub personal access token**: Paste your token
7. Click **Done** → **Save**

## Recommendation

**Stick with CodeConnections** (GitHub Version 2) as it's more secure and doesn't require managing tokens. Just fix the IAM permissions as outlined in `FIX_CODECONNECTIONS_PERMISSIONS.md`.

## Your Current Connection Status

To check your connection:
1. Go to **Developer Tools** → **Connections**
2. Look for connection ID: `21edde58-9108-4365-9c7c-de569ad473d8`
3. If status is **Pending**, click on it and complete the authorization
4. If status is **Available**, the issue is just IAM permissions

The connection name is whatever you named it when you first created it - it's just a friendly name for identification.
