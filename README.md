AWS Lambda and API Gateway Integration with Fillout API
This project demonstrates how to set up an AWS Lambda function to interact with the Fillout API, specifically for fetching form submissions. The Lambda function is triggered by AWS API Gateway, which exposes an endpoint to receive HTTP GET requests. The system forwards query parameters from the request to the Fillout API and returns the filtered form responses.

Testing
After deployment, you can test the endpoint using cURL, Postman, or any HTTP client:

bash
Copy code
https://1owzq0axt4.execute-api.us-west-1.amazonaws.com/dev/cLZojxk94ous/filteredResponses?limit=10&status=finished

Usage
Send a GET request to the deployed API Gateway endpoint with the desired query parameters. Supported parameters include limit, afterDate, beforeDate, offset, status, and includeEditLink.

Response Structure
The response will include an array of filtered responses based on the provided query parameters, along with metadata like totalResponses and pageCount.