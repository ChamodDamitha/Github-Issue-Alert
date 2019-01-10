import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/config;
import wso2/github4;

github4:GitHubConfiguration gitHubConfig = {
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            accessToken: config:getAsString("GITHUB_TOKEN")
        }
    }
};
github4:Client githubClient = new(gitHubConfig);

listener http:Listener httpListener = new(config:getAsInt("SERVICE_PORT"));

// Subscriber REST service
@http:ServiceConfig { basePath: "/github-alert" }
service GithubAlert on httpListener {
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
            // Send response to the client.
            var err = caller->respond(untaint payload);
            handleResponseError(err);
        } else {
            errResp.setJsonPayload({ "^error": "Request payload should be a json." });
            var err = caller->respond(errResp);
            handleResponseError(err);
        }
    }

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
            string[] tags_arr = jsonArrayToStringArray(issueReq.tags);
            string[] assignees_arr = jsonArrayToStringArray(issueReq.assignees);

            boolean status = createGithubIssue(untain(<string>issueReq.repo_owner), untain(<string>issueReq.repo_name),
                <string>issueReq.issue_title, <string>issueReq.issue_body,
                tags_arr, assignees_arr);

            if (status) {
                var jsonRet = findRepoByName(<string>issueReq.repo_name);
                // Send response to the client.
                json ret = null;

                if (jsonRet is string) {
                    ret = jsonRet;
                } else {
                    if (jsonRet == null) {
                        ret = insertNewRepo(<string>issueReq.repo_name);
                    } else {
                        string msg = io:sprintf("Issue : '%s' on Repository : '%s'", <string>issueReq.issue_title,
                            <string>issueReq.repo_name);
                        //sendSMS(jsonRet.subscribers, untain(msg));
                    }
                }
                var err = caller->respond(untaint ret);
                handleResponseError(err);
            }
        } else {
            errResp.setJsonPayload({ "^error": "Request payload should be a json." });
            var err = caller->respond(errResp);
            handleResponseError(err);
        }
    }
}

function createGithubIssue(string repo_owner, string repo_name, string issue_title, string issue_body,
                           string[] tags, string[] assignees) returns (boolean) {
    var createdIssue = githubClient->createIssue(repo_owner, repo_name, issue_title, issue_body, tags, assignees);
    if (createdIssue is github4:Issue) {
        io:println("Successfully posted issue");
        return true;
    } else {
        io:println("err:" + <string>createdIssue.detail().message);
        return false;
    }
}

function handleSubscribe(json|string returned, json subscribeReq) returns (json) {
    if (returned is string) {
        if (returned == MONGODB_RECORD_NOT_FOUND) {
            return {
                err: io:sprintf("Github Repository named '%s' is not open for subscription!",
                    <string>subscribeReq.repo_name)
            };
        } else {
            json err = {
                err: io:sprintf("find failed: %s", returned)
            };
            return err;
        }
    } else {
        io:println(returned);
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
            updateSubcribersInRepo(returned);
        }
        return returned;
    }
}

