# Adding Automated Testing to Your CodePipeline

This guide shows you how to add a build/test stage to your existing CodePipeline that will run automated tests (including verifying 2 + 2 = 4) before allowing deployment.

## What We've Created

### 1. **Calculator Logic Module** (`calculator.py`)
- Separated business logic from UI
- Pure functions that can be easily tested
- Proper error handling with custom exceptions

### 2. **Comprehensive Test Suite** (`test_calculator.py`)
- **24 test cases** covering all functionality
- **Your requested test**: `assert add(2, 2) == 4`
- Tests for basic arithmetic, scientific operations, error handling, and edge cases

### 3. **CodeBuild Configuration** (`buildspec.yml`)
- Installs dependencies (Python, pytest, streamlit)
- Runs all tests with verbose output
- Only proceeds if ALL tests pass
- Creates deployment artifacts

### 4. **Updated Application** (`app.py`)
- Now uses the testable calculator module
- Maintains the same user interface
- Better error handling through the calculator module

## Current Test Results

✅ **All 24 tests PASSED** including:
- `test_addition`: **2 + 2 = 4** ✅
- Division by zero handling
- Scientific operations (square root, trigonometry, etc.)
- Error cases and edge conditions
- Integration scenarios

## Pipeline Architecture

### Before (Current):
```
GitHub → CodeDeploy → EC2
```

### After (With Testing):
```
GitHub → CodeBuild (Tests) → CodeDeploy → EC2
                ↓
        Tests must pass or deployment stops
```

## Step-by-Step Implementation

### Step 1: Create CodeBuild Project

1. **Go to AWS Console → CodeBuild → Create build project**
2. **Project name**: `calculator-app-tests`
3. **Source provider**: GitHub
4. **Repository**: Select your repository
5. **Branch**: `main`
6. **Environment**:
   - **Environment image**: Managed image
   - **Operating system**: Amazon Linux 2
   - **Runtime**: Standard
   - **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
7. **Service role**: Create new service role or use existing
8. **Buildspec**: Use a buildspec file (it will find `buildspec.yml`)
9. **Artifacts**: No artifacts needed (CodePipeline will handle this)
10. **Click "Create build project"**

### Step 2: Update Your CodePipeline

1. **Go to CodePipeline Console**
2. **Select your pipeline**: `streamlit-deployment-pipeline`
3. **Click "Edit"**
4. **After the Source stage, click "Add stage"**
5. **Stage name**: `Build-and-Test`
6. **Add action group**:
   - **Action name**: `Test-Calculator`
   - **Action provider**: AWS CodeBuild
   - **Region**: Your region
   - **Input artifacts**: SourceOutput
   - **Project name**: `calculator-app-tests`
   - **Output artifacts**: `BuildOutput`
7. **Save the stage**
8. **Update the Deploy stage**:
   - **Edit the Deploy action**
   - **Change Input artifacts** from `SourceOutput` to `BuildOutput`
   - **Save**
9. **Save pipeline changes**

### Step 3: Test Your Pipeline

1. **Make a small change to your code**
2. **Commit and push to GitHub**:
   ```bash
   git add .
   git commit -m "Add automated testing to pipeline"
   git push
   ```
3. **Watch your pipeline run**:
   - **Source stage**: Pulls code from GitHub
   - **Build-and-Test stage**: Runs all 24 tests
   - **Deploy stage**: Only runs if tests pass

## What Happens During Testing

When the Build stage runs, you'll see output like this:

```
========================================
Starting Calculator Test Suite
========================================
test_calculator.py::TestBasicOperations::test_addition PASSED
test_calculator.py::TestBasicOperations::test_subtraction PASSED
test_calculator.py::TestBasicOperations::test_multiplication PASSED
test_calculator.py::TestBasicOperations::test_division PASSED
test_calculator.py::TestBasicOperations::test_division_by_zero PASSED
... (24 tests total)
========================================
All tests passed! ✅
Calculator functionality verified:
  ✅ 2 + 2 = 4 (Basic arithmetic)
  ✅ Division by zero handling
  ✅ Scientific operations
  ✅ Error handling
========================================
```

## Benefits of This Setup

### 🛡️ **Quality Assurance**
- **No broken code** reaches production
- **Automatic verification** of core functionality
- **Catches regressions** before deployment

### 🚀 **Confidence in Deployments**
- **Every deployment** is tested
- **Fast feedback** if something breaks
- **Rollback prevention** through testing

### 📊 **Comprehensive Coverage**
- **24 test scenarios** covering all functionality
- **Edge cases** and error conditions
- **Integration testing** of workflows

### 🔄 **Continuous Integration**
- **Automated testing** on every commit
- **No manual testing** required
- **Consistent quality** across deployments

## Test Categories

### 1. **Basic Operations** (Your Request!)
```python
def test_addition(self):
    assert add(2, 2) == 4  # Your requested test case!
    assert add(10, 5) == 15
    assert add(-1, 1) == 0
```

### 2. **Error Handling**
```python
def test_division_by_zero(self):
    with pytest.raises(CalculatorError):
        divide(5, 0)
```

### 3. **Scientific Operations**
```python
def test_square_root(self):
    assert square_root(4) == 2
    assert square_root(9) == 3
```

### 4. **Integration Scenarios**
```python
def test_calculator_workflow(self):
    # 2 + 2 = 4, then 4² = 16, then √16 = 4, then 4 ÷ 2 = 2
```

## Troubleshooting

### If Tests Fail
- **Pipeline stops** at the Build stage
- **Check CodeBuild logs** for specific test failures
- **Fix the code** and push again
- **Pipeline retries** automatically

### If Build Stage Fails
- **Check buildspec.yml** syntax
- **Verify dependencies** in requirements.txt
- **Check CodeBuild service role** permissions

### Common Issues
1. **Missing pytest**: Already handled in buildspec.yml
2. **Import errors**: Make sure all files are committed
3. **Permission issues**: CodeBuild service role needs access

## Next Steps

1. **Implement the pipeline changes** above
2. **Test with a small code change**
3. **Add more tests** as you add features
4. **Monitor build times** and optimize if needed

## Files Created/Modified

- ✅ `calculator.py` - Business logic module
- ✅ `test_calculator.py` - 24 comprehensive tests
- ✅ `buildspec.yml` - CodeBuild configuration
- ✅ `requirements.txt` - Added pytest dependency
- ✅ `app.py` - Updated to use calculator module

Your calculator app now has **enterprise-grade testing** that ensures **2 + 2 always equals 4** before any deployment! 🎉
