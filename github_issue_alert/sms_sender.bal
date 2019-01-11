import ballerina/config;
import wso2/twilio;
import ballerina/io;
import ballerina/log;

http:Client clientEndpoint = new("https://api.twilio.com", config = {
        auth: {
            scheme: http:BASIC_AUTH,
            username: config:getAsString("TWILIO_USERNAME"),
            password: config:getAsString("TWILIO_PASSWORD")
        }
    });

function sendSMS(json subscribers, string msg) {
    http:Request req = new;
    int l = subscribers.length();
    int i = 0;
    while (i < l) {
        string payload = io:sprintf("From=%s&To=%s&Body=%s", config:getAsString("TWILIO_SENDER_PHONE"),
            <string>subscribers[i], msg);
        payload = encodeUrl(payload);
        req.setTextPayload(payload);
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");

        string postUrl = io:sprintf("/2010-04-01/Accounts/%s/Messages.json", config:getAsString("TWILIO_USERNAME"));
        var response = clientEndpoint->post(postUrl, req);
        if (response is http:Response) {
            var returned = response.getJsonPayload();
            if (returned is json) {
                log:printInfo(returned.toString());
            } else {
                log:printError("Response is not json", err = returned);
            }
        } else {
            log:printError("Invalid response", err = response);
        }
        i = i + 1;
    }
}