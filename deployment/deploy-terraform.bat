@echo off
echo 🚀 Weather App Terraform Deployment
echo.

REM Check if Terraform is installed
terraform version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Terraform not found. Please install Terraform first.
    echo Download from: https://www.terraform.io/downloads
    exit /b 1
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS credentials not configured. Run: aws configure
    exit /b 1
)

echo 📦 Initializing Terraform...
cd terraform
terraform init

echo.
echo 📋 Planning deployment...
terraform plan

echo.
echo 🚀 Applying Terraform configuration...
terraform apply -auto-approve

if %errorlevel% neq 0 (
    echo ❌ Deployment failed
    exit /b 1
)

echo.
echo 🔍 Getting URLs...
for /f "tokens=*" %%i in ('terraform output -raw api_url') do set API_URL=%%i
for /f "tokens=*" %%i in ('terraform output -raw website_url') do set WEBSITE_URL=%%i
cd ..

echo.
echo ✅ Terraform deployment complete!
echo 🌐 API URL: %API_URL%
echo 🌐 Website URL: %WEBSITE_URL%
echo 🌐 Test API: %API_URL%?city=London
echo.
echo To destroy: terraform destroy
pause