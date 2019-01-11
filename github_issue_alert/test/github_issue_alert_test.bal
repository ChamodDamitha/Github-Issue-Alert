import ballerina/log;
import ballerina/test;
import ballerina/http;

http:Client apiClientEndpoint = new("http://localhost:9090/github-alert");

@test:Config
function testPostIssueAndSubscribe() {
    log:printDebug("Github Issue Alert -> Post an issue to a Github repository");
    json payload = {
        "repo_owner": "ChamodDamitha",
        "repo_name": "Test-Repo-2",
        "issue_title": "This is a test issue 1243 with API",
        "issue_body": "This is the body of the test issue 1234 with API",
        "tags": ["bug"],
        "assignees": []
    };
    http:Request req = new;
    req.setJsonPayload(payload);
    var postIssueResponse = apiClientEndpoint->post("/postIssue", req);
    if (postIssueResponse is http:Response) {
        var returned = postIssueResponse.getJsonPayload();
        if (returned is json) {
            if (<boolean>returned.status) {
                test:assertEquals(returned.msg,
                    "Issue : 'This is a test issue 1243 with API' on Repository : 'ChamodDamitha/Test-Repo-2'");

                http:Request reqSubscribe = new;
                reqSubscribe.setJsonPayload({
                        "repo_name": "ChamodDamitha/Test-Repo-2",
                        "contact": "+94777777777"
                    });
                var subscribeResponse = apiClientEndpoint->post("/subscribe", req);
                if (subscribeResponse is http:Response) {
                    var returnedResponse = subscribeResponse.getJsonPayload();
                    if (returnedResponse is json) {
                        if (returnedResponse.err != null) {
                            test:assertEquals(returnedResponse.err,
                                "Github Repository named 'ChamodDamitha/Test-Repo-2' is not open for subscription!");
                        } else {
                            test:assertEquals(returnedResponse.repo_name, "ChamodDamitha/Test-Repo-2");
                        }
                    }
                }
            } else {
                test:assertEquals(returned.msg, GITHUB_ISSUE_POSTING_FAILED);
            }
        }
    }
}