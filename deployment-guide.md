# Deployment Guide

## 🚀 Terraform Deployment

### Prerequisites
1. AWS Account with CLI configured (`aws configure`)
2. Terraform installed (https://www.terraform.io/downloads)
3. OpenWeatherMap API Key (free at https://openweathermap.org/api)

### Deploy
```bash
# Windows
deployment\deploy-terraform.bat

# Or direct Terraform
cd deployment\terraform
terraform init
terraform apply

# Or NPM
npm run deploy
```

### Destroy
```bash
cd deployment\terraform
terraform destroy
# or
npm run destroy
```

The deployment will:
- Deploy Lambda function via Terraform
- Create API Gateway with proper CORS
- Set up IAM roles and permissions
- Update index.html with API URL