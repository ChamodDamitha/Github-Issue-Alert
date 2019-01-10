# GitHub Issue Alert Endpoint
GitHub Issue Alert provides a Ballerina API to subscribe to different Github repositories and post Github issues so that the subscribers get notified via SMS. 

### Getting started

* Clone the repository by running the following command
```shell
git clone https://github.com/ChamodDamitha/Github-Issue-Alert.git
```

* Initialize the ballerina project.
```shell
ballerina init
```
* Create a file called `ballerina.conf` and include the following cofigurations
```shell
SERVICE_PORT = 9090

MONGODB_HOST = "localhost"
MONGODB_DB_NAME = "testdb"
MONGODB_USERNAME = ""
MONGODB_PASSWORD = ""
MONGODB_COLLECTION_NAME = "subscriber"

GITHUB_TOKEN = "YOUR_GITHUB_TOKEN"

TWILIO_USERNAME = "YOUR_TWILIO_ACCOUNT_SSID"
TWILIO_PASSWORD = "YOUR_TWILIO_AUTH_TOKEN"
TWILIO_SENDER_PHONE = "YOUR_TWILIO_PHONE_NUMBER_TO_SEND_SMS"
```
 
### Endpoints

* Subscribe to Github repository
##### Example
Request

```shell
curl -X POST \
  http://localhost:9090/github-alert/subscribe \
  -H 'Content-Type: application/json' \
  -d '{
    "repo_name": "ChamodDamitha/Test-Repo-2",
    "contact": "+94771111111"
}'
```
Response

```shell
{
    "_id": {
        "$oid": "5c3700b6ff49ef05c44929f4"
    },
    "repo_name": "Test-Repository",
    "subscribers": [
        "+94771111111"
    ]
}
```
* Post a Git Issue

Request

```shell
curl -X POST \
  http://localhost:9090/github-alert/postIssue \
  -H 'Content-Type: application/json' \
  -d '{
	"repo_owner":"ChamodDamitha",
	"repo_name":"Test-Repo-2",
	"issue_title":"This is a test issue 1243 with API",
	"issue_body":"This is the body of the test issue 1234 with API",
	"tags":["bug"],
	"assignees":["ChamodDamitha"]
}'
```
Response

```shell
{
    "status": true,
    "msg": "Issue : 'This is a test issue 1243 with API' on Repository : 'ChamodDamitha/Test-Repo-2'"
}
```

***