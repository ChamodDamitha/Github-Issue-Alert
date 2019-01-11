import wso2/mongodb;
import ballerina/config;

//Create a MongoDB client
mongodb:Client conn = new({
        host: config:getAsString("MONGODB_HOST"),
        dbName: config:getAsString("MONGODB_DB_NAME"),
        username: config:getAsString("MONGODB_USERNAME"),
        password: config:getAsString("MONGODB_PASSWORD"),
        options: { sslEnabled: false, serverSelectionTimeout: 500 }
    });

//Search for a Github Repository record by the name
function findRepoByName(string repo_name) returns (json|string) {
    json queryString = { "repo_name": repo_name };
    var jsonRet = conn->findOne(config:getAsString("MONGODB_COLLECTION_NAME"), queryString);

    if (jsonRet is json) {
        if (jsonRet != null) {
            return jsonRet;
        } else {
            return <string>MONGODB_RECORD_NOT_FOUND;
        }
    } else {
        return <string>jsonRet.reason();
    }
}

//Insert a new Github repository record
function insertNewRepo(string repo_name) returns (json) {
    json doc = { "repo_name": repo_name, "subscribers": [] };
    var ack = conn->insert(config:getAsString("MONGODB_COLLECTION_NAME"), doc);
    if (ack is ()) {
        return {
            status: true,
            msg: "Success repo record insert"
        };
    } else {
        return {
            status: false,
            msg: ack.reason()
        };
    }
}

//Update the subscribers to a Github repository
function updateSubcribersInRepo(json repo) {
    json filter = { "_id": repo._id };
    json document = { "$set": { "subscribers": repo.subscribers } };
    var result = conn->update(config:getAsString("MONGODB_COLLECTION_NAME"), filter, document, true, false);
}