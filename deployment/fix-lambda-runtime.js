const AWS = require('aws-sdk');

const lambda = new AWS.Lambda({ region: 'ap-south-1' });

async function updateLambdaRuntime() {
    try {
        // Update weather-deploy-function runtime
        await lambda.updateFunctionConfiguration({
            FunctionName: 'weather-deploy-function',
            Runtime: 'nodejs18.x'
        }).promise();
        
        console.log('Updated weather-deploy-function runtime to Node.js 18.x');
        
        // Update weather-function runtime
        await lambda.updateFunctionConfiguration({
            FunctionName: 'weather-function',
            Runtime: 'nodejs18.x'
        }).promise();
        
        console.log('Updated weather-function runtime to Node.js 18.x');
        
    } catch (error) {
        console.error('Error updating Lambda runtime:', error);
    }
}

updateLambdaRuntime();