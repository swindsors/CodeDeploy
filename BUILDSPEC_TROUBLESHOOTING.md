# BuildSpec Troubleshooting Guide

## Common BuildSpec YAML Errors and Solutions

### Error: "YAML_FILE_ERROR: Expected Commands[3] to be of string type"

**Problem**: YAML syntax error in buildspec.yml file.

**Common Causes:**
1. **Dynamic commands in artifact names** (like `$(date +%Y-%m-%d-%H-%M-%S)`)
2. **Incorrect indentation**
3. **Missing quotes around special characters**
4. **Empty values or malformed YAML structure**

**Solution Applied:**
```yaml
# ❌ WRONG - Causes YAML parsing error
artifacts:
  files:
    - '**/*'
  name: calculator-app-$(date +%Y-%m-%d-%H-%M-%S)

# ✅ CORRECT - Simple static name
artifacts:
  files:
    - '**/*'
  name: calculator-app-build
```

### Other Common BuildSpec Issues

#### 1. **Runtime Version Errors**
```yaml
# Make sure Python version is supported
install:
  runtime-versions:
    python: 3.11  # Use supported version
```

#### 2. **Command Failures**
```yaml
# Each command should be a simple string
commands:
  - echo "This works"
  - python -m pytest test_calculator.py -v
  - echo "This also works"
```

#### 3. **Path Issues**
```yaml
# Use proper paths for cache
cache:
  paths:
    - '/root/.cache/pip/**/*'  # Correct pip cache path
```

## Testing Your BuildSpec Locally

You can test parts of your buildspec locally:

```bash
# Test the install phase
python -m pip install --upgrade pip
pip install pytest
pip install streamlit==1.28.1
pip install -r requirements.txt

# Test the build phase
python -m pytest test_calculator.py -v --tb=short
```

## BuildSpec Best Practices

1. **Keep artifact names simple** - avoid dynamic commands
2. **Use explicit paths** - don't rely on relative paths
3. **Test commands locally first** - verify they work on your machine
4. **Use proper YAML indentation** - 2 spaces, no tabs
5. **Quote special characters** - when in doubt, use quotes

## Fixed BuildSpec Structure

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.11
    commands:
      - echo "Installing dependencies..."
      - python -m pip install --upgrade pip
      - pip install pytest
      - pip install streamlit==1.28.1
      - pip install -r requirements.txt
      
  pre_build:
    commands:
      - echo "Running pre-build checks..."
      - python --version
      - pip --version
      - pytest --version
      - echo "Listing project files..."
      - ls -la
      
  build:
    commands:
      - echo "Running tests..."
      - python -m pytest test_calculator.py -v --tb=short
      - echo "All tests passed!"
      
  post_build:
    commands:
      - echo "Build completed successfully!"

artifacts:
  files:
    - '**/*'
  name: calculator-app-build
  
cache:
  paths:
    - '/root/.cache/pip/**/*'
```

The buildspec.yml file has been fixed and should now work correctly in your CodeBuild project!
