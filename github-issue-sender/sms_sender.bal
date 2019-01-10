import ballerina/config;
import ballerina/http;
import wso2/mongodb;
import wso2/github4;
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
        string payload = "From=" + config:getAsString("TWILIO_SENDER_PHONE") + "&To=" + <string>subscribers[i] +
                "&Body=" + msg;
        payload = payload.replaceAll("\\+", "%2B");
        req.setTextPayload(payload);
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");

        io:println(req.getPayloadAsString());

        var response = clientEndpoint->post("/2010-04-01/Accounts/" + config:getAsString("TWILIO_USERNAME") +
                "/Messages.json", req
        );
        if (response is http:Response) {
            var returned = response.getJsonPayload();
            if (returned is json) {
                io:println(returned.toString());
            } else {
                log:printError("Response is not json", err = returned);
            }
        } else {
            log:printError("Invalid response", err = response);
        }
        i = i + 1;
    }
}