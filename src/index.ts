import { APIGatewayProxyHandler } from 'aws-lambda';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const { API_KEY } = process.env;

export const handler: APIGatewayProxyHandler = async (event) => {
  const formId = event.pathParameters?.formId;
  if (!formId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'No form ID provided in the path parameters.' })
    };
  }

  const queryParams: any = {
    ...event.queryStringParameters
  };
  const apiUrl = `https://api.fillout.com/v1/api/forms/${formId}/submissions`;

  try {
    const response = await axios.get(apiUrl, {
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      params: queryParams
    });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        responses: response.data.responses,
        totalResponses: response.data.totalResponses,
        pageCount: response.data.pageCount
      })
    };
  } catch (error: any) {
    console.error(error);
    return {
      statusCode: error.response?.status || 500,
      body: JSON.stringify({ message: error.message || 'Internal server error' })
    };
  }
};
