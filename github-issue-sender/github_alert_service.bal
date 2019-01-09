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

github4:GitHubConfiguration gitHubConfig = {
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            accessToken: "8ead1c4ae8081cb353823e397ac9d033c5acb8ea" //OAUTH2config:getAsString("GITHUB_TOKEN")
        }
    }
};
github4:Client githubClient = new(gitHubConfig);

listener http:Listener httpListener = new(9090);

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
            json queryString = { "repo_name": subscribeReq.repo_name };
            var jsonRet = conn->findOne("subscriber", queryString);
            json payload = handleSubscribe(jsonRet, subscribeReq);

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

            json tags = issueReq.tags;
            int l = tags.length();
            int i = 0;
            string[] tags_arr = [];
            while (i < l) {
                tags_arr[i] = <string>tags[i];
                i = i + 1;
            }

            json assignees = issueReq.assignees;
            l = assignees.length();
            i = 0;
            string[] assignees_arr = [];
            while (i < l) {
                assignees_arr[i] = <string>assignees[i];
                i = i + 1;
            }

            boolean status = createGithubIssue(untain(<string>issueReq.repo_owner), untain(<string>issueReq.repo_name),
                <string>issueReq.issue_title,<string>issueReq.issue_body,
                tags_arr, assignees_arr);

            if (status) {
                json queryString = { "repo_name": issueReq.repo_name };
                //io:println(queryString);
                var jsonRet = conn->findOne("subscriber", queryString);
                // Send response to the client.
                json ret = null;

                if (jsonRet is json) {
                    if (jsonRet == null) {
                        json doc = { "repo_name": issueReq.repo_name, "subscribers": [] };
                        var ack = conn->insert("subscriber", doc);
                        if (ack is ()) {
                            ret = "Success repo record insert";
                        } else {
                            ret = ack.reason();
                        }
                    } else {
                        string msg = "Issue : " + <string>issueReq.issue_title + " on Repository : " + <string>issueReq.repo_name;
                        sendSMS(jsonRet.subscribers, untain(msg));
                    }
                } else {
                    ret = jsonRet.reason();
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

function untain(string x) returns @untainted string{
    return x;
}

function createGithubIssue(string repo_owner, string repo_name, string issue_title, string issue_body,
                           string[] tags, string[] assignees) returns (boolean) {
    //github4:Repository|error result = githubClient->getRepository(repo_owner + "/" + repo_name);

    var createdIssue = githubClient->createIssue(repo_owner, repo_name, issue_title, issue_body, tags, assignees);
    if (createdIssue is github4:Issue) {
        io:println("Successfully posted issue");
        return true;
    } else {
        io:println("err:" + <string>createdIssue.detail().message);
        return false;
    }


    //github4:Repository issueRepository = { owner: { login: "ChamodDamitha" }, name: "Test-Repo" };
    //github4:IssueList issueList = new;
    //var issues = githubClient->getIssueList(issueRepository, github4:STATE_CLOSED, 5);
    //if (issues is github4:IssueList) {
    //    issueList = issues;
    //} else {
    //    io:println(<string>issues.detail().message);
    //}
}



function handleResponseError(error? err) {
    if (err is error) {
        log:printError("Respond failed", err = err);
    }
}

function handleSubscribe(json|error returned, json subscribeReq) returns (json) {
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

