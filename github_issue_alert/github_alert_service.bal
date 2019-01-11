import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/config;

listener http:Listener httpListener = new(config:getAsInt("SERVICE_PORT"));

// Github Issue Alert REST service
@http:ServiceConfig { basePath: "/github-alert" }
service GithubAlert on httpListener {
    //Subscribe endpoint
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/subscribe"
    }
    resource function subscribe(http:Caller caller, http:Request req) {
        var subscribeReq = req.getJsonPayload();
        http:Response errResp = new;
        errResp.statusCode = 500;
        if (subscribeReq is json) {
            var returned = findRepoByName(<string>subscribeReq.repo_name);
            json payload = handleSubscribe(returned, subscribeReq);
            var err = caller->respond(untaint payload);
            handleResponseError(err);
        } else {
            errResp.setJsonPayload({ "^error": "Request payload should be a json." });
            var err = caller->respond(errResp);
            handleResponseError(err);
        }
    }

    //Posting Github issue endpoint
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/postIssue"
    }
    resource function postIssue(http:Caller caller, http:Request req) {
        var issueReq = req.getJsonPayload();
        http:Response errResp = new;
        errResp.statusCode = 500;
        if (issueReq is json) {
            io:println(issueReq);
            json ret = handlePostIssue(issueReq);
            var err = caller->respond(untaint ret);
            handleResponseError(err);
        } else {
            errResp.setJsonPayload({ "^error": "Request payload should be a json." });
            var err = caller->respond(errResp);
            handleResponseError(err);
        }
    }
}
