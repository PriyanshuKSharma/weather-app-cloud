import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Step Function for Weather App Deployment Workflow
    """
    
    step = event.get('step', 'start')
    
    try:
        if step == 'start':
            return start_deployment(event)
        elif step == 'validate_resources':
            return validate_resources(event)
        elif step == 'deploy_lambda':
            return deploy_lambda(event)
        elif step == 'deploy_api':
            return deploy_api_gateway(event)
        elif step == 'deploy_website':
            return deploy_website(event)
        elif step == 'complete':
            return complete_deployment(event)
    except Exception as e:
        return {
            'statusCode': 500,
            'step': 'error',
            'message': f'Workflow error: {str(e)}'
        }

def start_deployment(event):
    """Initialize deployment workflow"""
    return {
        'statusCode': 200,
        'step': 'validate_resources',
        'timestamp': datetime.utcnow().isoformat(),
        'message': 'Starting weather app deployment',
        'config': {
            'region': event.get('region', 'ap-south-1'),
            'api_key': event.get('weather_api_key'),
            'bucket_name': event.get('bucket_name')
        }
    }

def validate_resources(event):
    """Validate AWS resources and permissions"""
    try:
        lambda_client = boto3.client('lambda')
        s3_client = boto3.client('s3')
        
        # Check if resources exist
        resources_status = {
            'lambda_exists': check_lambda_exists(lambda_client),
            'bucket_exists': check_bucket_exists(s3_client, event['config']['bucket_name']),
            'api_key_valid': bool(event['config']['api_key'])
        }
        
        if all(resources_status.values()):
            return {
                'statusCode': 200,
                'step': 'deploy_lambda',
                'message': 'Resources validated successfully',
                'resources': resources_status
            }
        else:
            return {
                'statusCode': 400,
                'step': 'error',
                'message': 'Resource validation failed',
                'resources': resources_status
            }
            
    except Exception as e:
        return {
            'statusCode': 500,
            'step': 'error',
            'message': f'Validation error: {str(e)}'
        }

def deploy_lambda(event):
    """Deploy Lambda function"""
    try:
        lambda_client = boto3.client('lambda')
        
        # Update Lambda function code
        response = lambda_client.update_function_code(
            FunctionName='weather-function',
            S3Bucket=event['config']['bucket_name'],
            S3Key='weather-function.zip'
        )
        
        # Update environment variables
        lambda_client.update_function_configuration(
            FunctionName='weather-function',
            Environment={
                'Variables': {
                    'WEATHER_API_KEY': event['config']['api_key']
                }
            }
        )
        
        return {
            'statusCode': 200,
            'step': 'deploy_api',
            'message': 'Lambda function deployed successfully',
            'lambda_arn': response['FunctionArn']
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'step': 'error',
            'message': f'Lambda deployment failed: {str(e)}'
        }

def deploy_api_gateway(event):
    """Deploy API Gateway"""
    try:
        apigateway = boto3.client('apigatewayv2')
        
        # Get API details
        apis = apigateway.get_apis()
        weather_api = next((api for api in apis['Items'] if api['Name'] == 'weather-api'), None)
        
        if weather_api:
            api_url = f"https://{weather_api['ApiId']}.execute-api.{event['config']['region']}.amazonaws.com/weather"
            
            return {
                'statusCode': 200,
                'step': 'deploy_website',
                'message': 'API Gateway configured successfully',
                'api_url': api_url
            }
        else:
            return {
                'statusCode': 404,
                'step': 'error',
                'message': 'Weather API not found'
            }
            
    except Exception as e:
        return {
            'statusCode': 500,
            'step': 'error',
            'message': f'API Gateway deployment failed: {str(e)}'
        }

def deploy_website(event):
    """Deploy website to S3"""
    try:
        s3_client = boto3.client('s3')
        
        # Read index.html template
        with open('/tmp/index.html', 'r') as f:
            html_content = f.read()
        
        # Replace API URL
        updated_html = html_content.replace('YOUR_API_GATEWAY_URL_HERE', event['api_url'])
        
        # Upload to S3
        s3_client.put_object(
            Bucket=event['config']['bucket_name'],
            Key='index.html',
            Body=updated_html,
            ContentType='text/html'
        )
        
        website_url = f"http://{event['config']['bucket_name']}.s3-website-{event['config']['region']}.amazonaws.com"
        
        return {
            'statusCode': 200,
            'step': 'complete',
            'message': 'Website deployed successfully',
            'website_url': website_url
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'step': 'error',
            'message': f'Website deployment failed: {str(e)}'
        }

def complete_deployment(event):
    """Complete deployment workflow"""
    return {
        'statusCode': 200,
        'step': 'finished',
        'message': 'Weather app deployment completed successfully',
        'deployment_summary': {
            'api_url': event.get('api_url'),
            'website_url': event.get('website_url'),
            'timestamp': datetime.utcnow().isoformat()
        }
    }

def check_lambda_exists(lambda_client):
    """Check if Lambda function exists"""
    try:
        lambda_client.get_function(FunctionName='weather-function')
        return True
    except:
        return False

def check_bucket_exists(s3_client, bucket_name):
    """Check if S3 bucket exists"""
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        return True
    except:
        return False