const AWS = require('aws-sdk');
const archiver = require('archiver');

const lambda = new AWS.Lambda();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const action = event.action;
    
    try {
        if (action === 'update_lambda') {
            await updateLambdaFunction();
            return { statusCode: 200, body: 'Lambda updated successfully' };
        } else if (action === 'update_s3') {
            await updateS3Website();
            return { statusCode: 200, body: 'S3 updated successfully' };
        }
    } catch (error) {
        console.error('Deployment error:', error);
        return { statusCode: 500, body: `Error: ${error.message}` };
    }
};


async function updateLambdaFunction() {
    const sourceKey = 'weather-function.js';
    const sourceBucket = process.env.SOURCE_BUCKET;
    
    const sourceCode = await s3.getObject({
        Bucket: sourceBucket,
        Key: sourceKey
    }).promise();
    
    const zipBuffer = await createZipBuffer(sourceCode.Body.toString());
    
    await lambda.updateFunctionCode({
        FunctionName: 'weather-function',
        ZipFile: zipBuffer
    }).promise();
    
    console.log('Lambda function updated successfully');
}

async function updateS3Website() {
    const apiUrl = process.env.API_URL;
    
    const indexTemplate = await s3.getObject({
        Bucket: process.env.SOURCE_BUCKET,
        Key: 'index.html'
    }).promise();
    
    const updatedHtml = indexTemplate.Body.toString()
        .replace('YOUR_API_GATEWAY_URL_HERE', apiUrl);
    
    await s3.putObject({
        Bucket: process.env.WEBSITE_BUCKET,
        Key: 'index.html',
        Body: updatedHtml,
        ContentType: 'text/html'
    }).promise();
    
    console.log('S3 website updated successfully');
}

function createZipBuffer(sourceCode) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        const archive = archiver('zip');
        
        archive.on('data', chunk => chunks.push(chunk));
        archive.on('end', () => resolve(Buffer.concat(chunks)));
        archive.on('error', reject);
        
        archive.append(sourceCode, { name: 'index.js' });
        archive.finalize();
    });
}