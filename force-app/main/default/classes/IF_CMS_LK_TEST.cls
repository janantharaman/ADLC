@RestResource(urlMapping='/cms/test')
global with sharing class IF_CMS_LK_TEST {
    private static final String API_NAME = IF_CMS_LK_TEST.class.getName();

    @HttpPost
    global static void post() {
        try {
            Logger.setScenario(API_NAME);

            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            Logger.info('Recieved POST request with body: ' + requestBody).setRestRequestDetails(req);

            for (String headerName : req.headers.keySet()) {
                Logger.info('Header: ' + headerName + ' = ' + req.headers.get(headerName));
            }

            // Deserialize the request body into a Request object
            Request requestObj = (Request) JSON.deserialize(requestBody, Request.class);

            // Process the request (for demonstration, we just log the message)
            Logger.info('Processing message: ' + requestObj.message);

            // Create a response object
            Response responseObj = new Response();

            if (requestObj.message == 'LK') {
                responseObj.status = 'success';
                responseObj.message = 'CMS';
                RestContext.response.statusCode = 200;
            } else {
                responseObj.status = 'error';
                responseObj.message = 'error';
                RestContext.response.statusCode = 400;
            }

            // Serialize the response object to JSON and set it as the response body
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            Logger.info('Response sent: ' + JSON.serialize(responseObj)).setRestResponseDetails(RestContext.response);
        } catch (JSONException e) {
            Logger.error('JSON parsing error: ' + e.getMessage()).setExceptionDetails(e);

            Response errorResponse = new Response();
            errorResponse.status = 'error';
            errorResponse.message = String.format(
                'Invalid JSON format | {0} | {1}',
                new List<String>{ e.getTypeName(), e.getMessage() }
            );

            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
            Logger.info('Error response sent: ' + JSON.serialize(errorResponse))
                .setRestResponseDetails(RestContext.response);
        } catch (Exception e) {
            Logger.error('Error processing POST request: ' + e.getMessage()).setExceptionDetails(e);

            Response errorResponse = new Response();
            errorResponse.status = 'error';
            errorResponse.message = String.format(
                'An error occurred while processing the request | {0} | {1}',
                new List<String>{ e.getTypeName(), e.getMessage() }
            );

            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
            Logger.info('Error response sent: ' + JSON.serialize(errorResponse))
                .setRestResponseDetails(RestContext.response);
        } finally {
            Logger.saveLog();
        }
    }

    public class Request {
        public String message;
    }

    public class Response {
        public String status;
        public String message;
    }
}