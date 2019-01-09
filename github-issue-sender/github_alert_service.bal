import ballerina/http;
import ballerina/log;
import wso2/mongodb;
import ballerina/io;

mongodb:Client conn = new({
        host: "localhost",
        dbName: "testdb",
        username: "",
        password: "",
        options: { sslEnabled: false, serverSelectionTimeout: 500 }
    });

listener http:Listener httpListener = new(9090);

// Subscriber REST service
@http:ServiceConfig { basePath: "/github-alert" }
service GithubAlert on httpListener {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/subscribe"
    }
    resource function executeOperation(http:Caller caller, http:Request req) {
        var subscribeReq = req.getJsonPayload();
        http:Response errResp = new;
        errResp.statusCode = 500;
        if (subscribeReq is json) {
            json queryString = { "repo_name": subscribeReq.repo_name };
            var jsonRet = conn->findOne("subscriber", queryString);
            json payload = handleFind(jsonRet, subscribeReq);

            // Send response to the client.
            var err = caller->respond(untaint payload);
            handleResponseError(err);
        } else {
            errResp.setJsonPayload({ "^error": "Request payload should be a json." });
            var err = caller->respond(errResp);
            handleResponseError(err);
        }
    }
}

function handleResponseError(error? err) {
    if (err is error) {
        log:printError("Respond failed", err = err);
    }
}

function handleFind(json|error returned, json subscribeReq) returns (json) {
    if (returned is json) {
        io:println(returned);
        if (returned != null) {
            var alreadySubscribed = false;
            json subscribers = returned.subscribers;
            int l = subscribers.length();
            int i = 0;
            while (i < l) {
                io:println(subscribers[i]);
                if (subscribers[i] == subscribeReq.contact) {
                    alreadySubscribed = true;
                    break;
                }
                i = i + 1;
            }
            if (!alreadySubscribed) {
                returned.subscribers[returned.subscribers.length()] = subscribeReq.contact;
                json filter = { "_id": returned._id };
                json document = { "$set": { "subscribers": returned.subscribers } };
                var result = conn->update("subscriber", filter, document, true, false);
            }
        } else {
            return {
                err: "Github Repository named '" + <string>subscribeReq.repo_name + "' is not open for subscription!"
            };
        }
        return returned;
    } else {
        json err = {
            err: "find failed: " + returned.reason()
        };
        return err;
    }
}
