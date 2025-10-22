# Cloud Weather Dashboard

A serverless weather application using AWS Lambda, API Gateway, and OpenWeatherMap API.

## 🚀 Quick Start

1. Get OpenWeatherMap API key from https://openweathermap.org/api
2. Deploy Lambda function from `lambda/weather-function.js`
3. Create API Gateway and connect to Lambda
4. Update `index.html` with your API Gateway URL
5. Open `index.html` in browser

## 📁 Project Structure

```
weather-app-cloud/
├── deployment/
│   ├── terraform/             # Terraform infrastructure
│   ├── auto-deploy.js         # Automated deployment script
│   ├── deploy-lambda.js       # Step Function Lambda
│   └── deploy-terraform.bat   # Windows deployment script
├── lambda/
│   └── weather-function.js    # AWS Lambda function
├── step-function/
│   ├── weather_deployment_workflow.py  # Python Step Function
│   └── step_function_definition.json   # State machine definition
├── images/
│   ├── lambda-template.png    # Lambda function template
│   └── stepfunctions_graph.png # Step Functions workflow diagram
├── index.html                 # Frontend dashboard
├── deployment-guide.md        # Step-by-step deployment
└── README.md                  # This file
```

## 🏗️ Architecture

```
User → HTML/JS Frontend → API Gateway → Lambda → OpenWeatherMap API
```

### Step Functions Workflow
![Step Functions Workflow](images/stepfunctions_graph.png)

### Lambda Template
![Lambda Template](images/lambda-template.png)

## 📋 Features

- ✅ City-based weather lookup
- ✅ Temperature, humidity, wind speed
- ✅ Responsive design
- ✅ Error handling
- ✅ CORS enabled

See `deployment-guide.md` for detailed setup instructions.
