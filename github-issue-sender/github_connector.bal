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

function createGithubIssue(string repo_owner, string repo_name, string issue_title, string issue_body,
                           string[] tags, string[] assignees) returns (boolean) {
    var createdIssue = githubClient->createIssue(repo_owner, repo_name, issue_title, issue_body, tags, assignees);
    return  (createdIssue is github4:Issue);
}

function handlePostIssue(json issueReq) returns (json){
    string[] tags_arr = jsonArrayToStringArray(issueReq.tags);
    string[] assignees_arr = jsonArrayToStringArray(issueReq.assignees);

    boolean status = createGithubIssue(untain(<string>issueReq.repo_owner), untain(<string>issueReq.repo_name),
        <string>issueReq.issue_title, <string>issueReq.issue_body,
        tags_arr, assignees_arr);

    json ret = null;
    if (status) {
        var jsonRet = findRepoByName(<string>issueReq.repo_name);

        if (jsonRet is string) {
            if (jsonRet == MONGODB_RECORD_NOT_FOUND) {
                ret = insertNewRepo(<string>issueReq.repo_name);
            } else {
                ret = jsonRet;
            }
        } else {
            string msg = io:sprintf("Issue : '%s' on Repository : '%s'", <string>issueReq.issue_title,
                <string>issueReq.repo_name);
            sendSMS(jsonRet.subscribers, untain(msg));
            ret = {
                "status" : true,
                "msg" : msg
            };
        }
    }
    return ret;
}