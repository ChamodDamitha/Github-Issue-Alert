import ballerina/config;
import ballerina/http;
import wso2/mongodb;
import wso2/github4;
import wso2/twilio;
import ballerina/io;
import ballerina/log;

//mongodb:Client conn = new({
//        host: "localhost",
//        dbName: "testdb",
//        username: "",
//        password: "",
//        options: { sslEnabled: false, serverSelectionTimeout: 500 }
//    });

//github4:GitHubConfiguration gitHubConfig = {
//    clientConfig: {
//        auth: {
//            scheme: http:OAUTH2,
//            accessToken:  "10b06b66e8823f8a760c8c842e99c6810e51f0b9"  //OAUTH2config:getAsString("GITHUB_TOKEN")
//        }
//    }
//};
//github4:Client githubClient = new(gitHubConfig);

twilio:TwilioConfiguration twilioConfig = {
    accountSId: "AC8d68bb621b89cfc4e02ff3ba87ff9f54", //config:getAsString(ACCOUNT_SID),
    authToken: "b0043c21662566c17474a6e2a86eac36" //config:getAsString(AUTH_TOKEN),
    //xAuthyKey: config:getAsString(AUTHY_API_KEY)
};
twilio:Client twilioClient = new(twilioConfig);

http:Client clientEndpoint = new("https://api.twilio.com", config = {
        auth: {
            scheme: http:BASIC_AUTH,
            username: "AC8d68bb621b89cfc4e02ff3ba87ff9f54",
            password: "b0043c21662566c17474a6e2a86eac36"
        }
    });


public function main() {
    //io:println("Hello, Chamod!");
    //
    //json queryString = { "repo_name": "test_repo_2" };
    //var jsonRet = conn->find("subscriber", queryString);
    //handleFind(jsonRet);
    //createGithubIssue();
    //sendSMS();
    //string stat = "From=+18647148814&To=+94710397382&Body=testing";
    //string rep = stat.replaceAll("\\+", "%2B");
    //io:println(rep);
}

//function createGithubIssue() {
//    github4:Repository|error result = githubClient->getRepository("ChamodDamitha/Test-Repo");
//    //if (result is github4:Repository) {
//    //    io:println("Repository ChamodDamitha/Test-Repo: ", result);
//    //} else {
//    //    io:println("Error occurred on getRepository(): ", result);
//    //}
//
//    io:println("githubClient -> createIssue()");
//    var createdIssue = githubClient->createIssue("ChamodDamitha", "Test-Repo",
//        "This is a test issue", "This is the body of the test issue 2", ["bug", "critical"], ["VirajSalaka"]);
//    if (createdIssue is github4:Issue) {
//        io:println("Success createIssue()");
//    } else {
//        io:println(createdIssue.detail().message);
//    }
//
//
//    //github4:Repository issueRepository = { owner: { login: "ChamodDamitha" }, name: "Test-Repo" };
//    //github4:IssueList issueList = new;
//    //var issues = githubClient->getIssueList(issueRepository, github4:STATE_CLOSED, 5);
//    //if (issues is github4:IssueList) {
//    //    issueList = issues;
//    //} else {
//    //    io:println(<string>issues.detail().message);
//    //}
//}

function sendSMS(json subscribers, string msg) {
    http:Request req = new;
    int l = subscribers.length();
    int i = 0;
    while (i < l) {
        string payload = "From=+18647148814&To=" + <string>subscribers[i] + "&Body=" + msg;
        payload = payload.replaceAll("\\+", "%2B");
        req.setTextPayload(payload);
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");

        io:println(req.getPayloadAsString());

        var response = clientEndpoint->post("/2010-04-01/Accounts/AC8d68bb621b89cfc4e02ff3ba87ff9f54/Messages.json", req
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



//function handleFind(json|error returned) {
//    if (returned is json) {
//        io:print("initial data:");
//        io:println(io:sprintf("%s", returned));
//        io:println(io:sprintf("%s", returned[0].subscribers[0]));
//    } else {
//        io:println("find failed: " + returned.reason());
//    }
//}


//https://api.twilio.com/2010-04-01/Accounts/AC8d68bb621b89cfc4e02ff3ba87ff9f5/SMS/Messages.json
//
//
//https://api.twilio.com/2010-04-01/Accounts/AC8d68bb621b89cfc4e02ff3ba87ff9f54/SMS/Messages.json


