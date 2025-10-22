@echo off
echo 🚀 Weather App SAM Deployment
echo.

REM Check if SAM CLI is installed
sam --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ SAM CLI not found. Please install SAM CLI first.
    echo Download from: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
    exit /b 1
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS credentials not configured. Run: aws configure
    exit /b 1
)

REM Get API key from user
set /p WEATHER_API_KEY="Enter your OpenWeatherMap API key: "
if "%WEATHER_API_KEY%"=="" (
    echo ❌ API key is required
    exit /b 1
)

echo.
echo 📦 Building SAM application...
sam build -t weather-lambda.yaml

if %errorlevel% neq 0 (
    echo ❌ Build failed
    exit /b 1
)

echo.
echo 🚀 Deploying SAM application...
sam deploy --guided --parameter-overrides WeatherApiKey=%WEATHER_API_KEY%

if %errorlevel% neq 0 (
    echo ❌ Deployment failed
    exit /b 1
)

echo.
echo ✅ SAM deployment complete!
echo 🌐 Check AWS CloudFormation console for stack outputs
pause