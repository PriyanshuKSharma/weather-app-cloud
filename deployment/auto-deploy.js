const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');

const s3 = new AWS.S3();
const stepfunctions = new AWS.StepFunctions();

// Configuration
const SOURCE_BUCKET = 'weather-source-56qa0x06'; // Update with your bucket name
const STEP_FUNCTION_ARN = 'arn:aws:states:ap-south-1:396907900627:stateMachine:weather-app-deploy'; // Update with your ARN

async function uploadAndDeploy() {
    try {
        console.log('📁 Uploading weather-function.js to S3...');
        
        // Upload weather function
        const functionCode = fs.readFileSync(path.join(__dirname, '..', 'lambda', 'weather-function.js'));
        await s3.putObject({
            Bucket: SOURCE_BUCKET,
            Key: 'weather-function.js',
            Body: functionCode
        }).promise();
        
        // Upload index.html
        const indexHtml = fs.readFileSync(path.join(__dirname, '..', 'index.html'));
        await s3.putObject({
            Bucket: SOURCE_BUCKET,
            Key: 'index.html',
            Body: indexHtml
        }).promise();
        
        console.log('✅ Files uploaded to S3');
        
        // Trigger Step Function
        console.log('🚀 Starting deployment pipeline...');
        const execution = await stepfunctions.startExecution({
            stateMachineArn: STEP_FUNCTION_ARN,
            input: JSON.stringify({
                timestamp: new Date().toISOString()
            })
        }).promise();
        
        console.log('✅ Deployment pipeline started:', execution.executionArn);
        console.log('🔍 Monitor progress in AWS Step Functions console');
        
    } catch (error) {
        console.error('❌ Deployment failed:', error.message);
    }
}

// Run if called directly
if (require.main === module) {
    uploadAndDeploy();
}

module.exports = { uploadAndDeploy };