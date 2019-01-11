function encodeUrl(string str) returns (string) {
    string encoded_str = str.replaceAll("\\+", "%2B");
    return encoded_str;
}

function untain(string x) returns @untainted string {
    return x;
}

function handleResponseError(error? err) {
    if (err is error) {
        log:printError("Respond failed", err = err);
    }
}

function jsonArrayToStringArray(json jsonArr) returns (string[]) {
    int l = jsonArr.length();
    int i = 0;
    string[] arr = [];
    while (i < l) {
        arr[i] = <string>jsonArr[i];
        i = i + 1;
    }
    return arr;
}
