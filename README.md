<!-- Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. -->

# Functionless URL Shortener
This app creates a URL shortener without using any compute. All business logic is handled at the Amazon API Gateway level. The basic app will create an API Gateway instance with a simple header-based user identification system. It will also create an Amazon DynamoDB table for data storage. It will also create a simple Vuejs application as a demo client.

Read the blog series about this application:
1. [Building a serverless URL shortener app without AWS Lambda – part 1](https://aws.amazon.com/blogs/compute/building-a-serverless-url-shortener-app-without-lambda-part-1)
1. [Building a serverless URL shortener app without AWS Lambda – part 2](https://aws.amazon.com/blogs/compute/building-a-serverless-url-shortener-app-without-lambda-part-2)
1. [Building a serverless URL shortener app without AWS Lambda – part 3](https://aws.amazon.com/blogs/compute/building-a-serverless-url-shortener-app-without-lambda-part-3)

## The Backend

### Services Used
* <a href="https://aws.amazon.com/api-gateway/" target="_blank">Amazon API Gateway</a>
* <a href="https://aws.amazon.com/dynamodb/" target="_bank">Amazon DynamoDB</a>
* <a href="https://aws.amazon.com/amplify/console/" target="_blank">AWS Amplify Console</a>
* <a href="https://aws.amazon.com/s3/" target="_blank">Amazon S3</a>


### Requirements for deployment
* <a href="https://aws.amazon.com/cli/" target="_blank">AWS CLI</a>
* <a href="https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html" target="_blank">AWS SAM CLI v0.37.0+</a>
* Forked copy of this repository. Instructions for forking a GitHib repository can be found <a href="https://help.github.com/en/github/getting-started-with-github/fork-a-repo" target="_blank">here</a>
* A GitHub personal access token with the *repo* scope as shown below. Instructions for creating a personal access token can be found <a href="https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line#creating-a-token" target="blank">here</a>

    ![Personal access token scopes](./assets/pat.png)

    **Be sure and store you new token in a place that you can find it.**

### Deploying

In the terminal, use the SAM CLI guided deployment the first time you deploy
```bash
sam deploy -g
```

#### Choose options
You can choose the default for all options except *GithubRepository* and **

```bash
## The name of the CloudFormation stack
Stack Name [URLShortener]:

## The region you want to deploy in
AWS Region [us-west-2]:

## The name of the application (lowercase no spaces). This must be globally unique
Parameter AppName [shortener]:

## Enables public client and local client for testing. (Less secure)
Parameter UseLocalClient [false]:

## GitHub forked repository URL
Parameter GithubRepository []:

## Github Personal access token
Parameter PersonalAccessToken:

## Shows you resources changes to be deployed and requires a 'Y' to initiate deploy
Confirm changes before deploy [y/N]: 

## SAM needs permission to be able to create roles to connect to the resources in your template
Allow SAM CLI IAM role creation [Y/n]:

## Save your choice for later deployments
Save arguments to samconfig.toml [Y/n]:
```

SAM will then deploy the AWS CloudFormation stack to your AWS account and provide required outputs for the included client.

After the first deploy you may re-deploy using `sam deploy` or redeploy with different options using `sam deploy -g`.

## The Client

*The client can also be run locally for debugging. Instructions can be found [here](./client/README.md).*

The client is a Vue.js application that interfaces with the backend and allows you to authenticate and manage URL links. The client is hosted using Amplify Console. To avoid circular dependencies, we need to provide some information for the client after stack is built. The information needed is provided at the end of the deploy process. If you do not have the information you can run the following:

```bash
aws cloudformation describe-stacks --stack-name URLShortener
```

We need to add this information to the environment variables for the Amplify Console app. There are two options for adding the variables.

#### Option 1: using the AWS CLI (Update the *\<values\>* to reflect the information returned from the deployment.)

```bash
aws amplify update-app --app-id <MyAmplifyAppId> --environment-variables \
VUE_APP_NAME=<VueAppName>\
,VUE_APP_CLIENT_ID=<VUE_APP_CLIENT_ID>\
,VUE_APP_API_ROOT=<VUE_APP_API_ROOT>\
,VUE_APP_AUTH_DOMAIN=<VUE_APP_AUTH_DOMAIN>
```

*Also available in the stack output as **AmplifyEnvironmentUpdateCommand***

#### Option 2: Amplify Console page
1. Open the [Amplify Console page](https://us-west-2.console.aws.amazon.com/amplify/home)
1. On the left side, under **All apps**, choose *Url-Shortner-Client*
1. Under **App settings** choose *Environment variables*
1. Choose the *manage variables* button
1. Choose *add variable*
1. Fill in the *variable* and it's corresponding *Value*
1. Leave defaults for *Branches* and *Actions*
1. Repeat for all four variables
1. Choose save

### Starting the first deployment
After deploying the CloudFormation template, you need to go into the Amplify Console and trigger a build. The CloudFormation template can provision the resources, but can’t trigger a build since it creates resources but cannot trigger actions. This can be done via the AWS CLI.

#### Option 1: Using the AWS CLI (Update the *\<values\>* to reflect the information returned from the deployment.)

```bash
aws amplify start-job --app-id <MyAmplifyAppId> --branch-name master --job-type RELEASE
```
*Also available in the stack output as **AmplifyDeployCommand***

To check on the status, you can view it on the AWS Amplify Console or run:
```bash
aws amplify get-job --app-id <MyAmplifyAppId> --branch-name master --job-id <JobId>
```

#### Option 2: Amplify Console page
1. Open the <a href="https://us-west-2.console.aws.amazon.com/amplify/home" target="_blank">Amplify Console page</a>
1. On the left side, under **All apps**, choose *Url-Shortner-Client*
1. Click *Run build*

*Note: this is only required for the first build subsequent client builds will be triggered when updates are committed to your forked repository.

## REST API Documentation

The application exposes a REST API through Amazon API Gateway that can be accessed directly. The API endpoint URL is available in the stack outputs as `VueAppAPIRoot`.

### API Endpoint

After deployment, your API will be accessible at:
```
https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod
```

You can find your specific endpoint URL by running:
```bash
aws cloudformation describe-stacks --stack-name URLShortener --query "Stacks[0].Outputs[?OutputKey=='VueAppAPIRoot'].OutputValue" --output text
```

### Authentication

Most API endpoints require user identification using a custom header. Include the user identifier in the `shortener-user-id` header:
```
shortener-user-id: <your-user-identifier>
```

**Note:** This header-based authentication is simple but not secure for production use. The user ID is not validated, so any client can impersonate any user. Consider implementing proper authentication (API keys, OAuth, etc.) for production deployments.

### API Endpoints

#### 1. Redirect to Full URL (Public)
Redirects to the full URL associated with a short link ID.

**Endpoint:** `GET /{linkId}`

**Parameters:**
- `linkId` (path) - The short link identifier

**Response:**
- `301 Redirect` - Redirects to the full URL
- Headers:
  - `Location` - The full URL to redirect to
  - `Cache-Control` - Cache settings

**Example:**
```bash
curl -L https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod/abc123
```

#### 2. Get All Links for User (Authenticated)
Retrieves all URL links created by the authenticated user.

**Endpoint:** `GET /app`

**Headers:**
- `shortener-user-id: <user-identifier>` (required)

**Response:**
- `200 OK` - Returns array of link objects
- Headers:
  - `Access-Control-Allow-Origin`
  - `Cache-Control: no-cache, no-store`

**Response Body:**
```json
[
  {
    "id": "abc123",
    "url": "https://example.com/very/long/url",
    "timestamp": "Wed, 05 Dec 2025 12:00:00 GMT",
    "owner": "user@example.com"
  }
]
```

**Example:**
```bash
curl -H "shortener-user-id: user@example.com" \
  https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod/app
```

#### 3. Create New Link (Authenticated)
Creates a new short URL link.

**Endpoint:** `POST /app`

**Headers:**
- `shortener-user-id: <user-identifier>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "id": "abc123",
  "url": "https://example.com/very/long/url"
}
```

**Response:**
- `200 OK` - Link created successfully
- `400 Bad Request` - Link ID already exists or validation error

**Success Response Body:**
```json
{
  "id": "abc123",
  "url": "https://example.com/very/long/url",
  "timestamp": "Wed, 05 Dec 2025 12:00:00 GMT",
  "owner": "user@example.com"
}
```

**Error Response Body:**
```json
{
  "error": true,
  "message": "URL link already exists"
}
```

**Example:**
```bash
curl -X POST \
  -H "shortener-user-id: user@example.com" \
  -H "Content-Type: application/json" \
  -d '{"id":"abc123","url":"https://example.com/long/url"}' \
  https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod/app
```

#### 4. Update Link (Authenticated)
Updates an existing short URL link. Only the owner can update their links.

**Endpoint:** `PUT /app/{linkId}`

**Parameters:**
- `linkId` (path) - The short link identifier to update

**Headers:**
- `shortener-user-id: <user-identifier>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "id": "abc123",
  "url": "https://example.com/updated/url"
}
```

**Response:**
- `200 OK` - Link updated successfully
- `400 Bad Request` - Permission denied or validation error

**Success Response Body:**
```json
{
  "id": "abc123",
  "url": "https://example.com/updated/url",
  "timestamp": "Wed, 05 Dec 2025 12:00:00 GMT",
  "owner": "user@example.com"
}
```

**Example:**
```bash
curl -X PUT \
  -H "shortener-user-id: user@example.com" \
  -H "Content-Type: application/json" \
  -d '{"id":"abc123","url":"https://example.com/new/url"}' \
  https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod/app/abc123
```

#### 5. Delete Link (Authenticated)
Deletes a short URL link. Only the owner can delete their links.

**Endpoint:** `DELETE /app/{linkId}`

**Parameters:**
- `linkId` (path) - The short link identifier to delete

**Headers:**
- `shortener-user-id: <user-identifier>` (required)

**Response:**
- `200 OK` - Link deleted successfully
- `400 Bad Request` - Permission denied or link not found

**Example:**
```bash
curl -X DELETE \
  -H "shortener-user-id: user@example.com" \
  https://{ApiId}.execute-api.{Region}.amazonaws.com/Prod/app/abc123
```

### CORS Support

The API includes CORS support with preflight handling via `OPTIONS` method on `/app` and `/app/{linkId}` endpoints.

### Rate Limiting

The API Gateway has the following throttling settings configured:
- Default: 2000 requests/second with burst of 1000
- GET `/{linkId}`: 10000 requests/second with burst of 4000

## Cleanup
1. Open the <a href="https://us-west-2.console.aws.amazon.com/cloudformation/home" target="_blank">CloudFormation console</a>
1. Locate a stack named *URLShortener*
1. Select the radio option next to it
1. Select **Delete**
1. Select **Delete stack** to confirm

*Note: If you opted to have access logs (on by default), you may have to delete the S3 bucket manually.
