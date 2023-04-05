def apiUrl = 'https://rca-nginx.runecast.svc:9080/rca/api/v2/images-scan-requests'
def apiToken = 'Token from RCA API'
properties(
    [disableConcurrentBuilds(),
     parameters(
         [string(defaultValue: '', name: "images", description: "image name", trim: true),
          string(defaultValue: '', name: "policyId", description: "policy Id", trim: true),
     )])

import groovy.json.JsonSlurperClassic
node {
	timestamps {
		try {
			if (images == null || images == "") error ("Enter one or more images")

            stage('Build') {
			    echo "Building and storing container image(s):"
			    echo "$images"
			}
								
			stage('Security check') {
                // build the request body
			    def requestObject = [ 'imageNames': [], 'policyId': policyId ]
                for (e in images.split("\\r?\\n|\\r")) {
			        requestObject.imageNames += e.trim()
                }
                String requestBody = writeJSON returnText: true, json: requestObject
			    echo "Sending API request with body $requestBody"

			    // send the API request
				def response = httpRequest url: "$apiUrl",
			                    httpMode: 'POST',
				                requestBody: requestBody,
				                contentType: 'APPLICATION_JSON',
				                acceptType: 'APPLICATION_JSON',
				                customHeaders: [[name: 'Authorization', value: "$apiToken"]],
				                consoleLogResponseBody: false,
				                ignoreSslErrors: true
                echo "Received API response with content ${response.content}"
                
                // parse the response
                def responseProperties = readJSON text: response.content
                def policyResult = responseProperties.scanResultCompliesWithPolicy

                // evaluate the results
                if (policyResult == false) {
                    error ('Scanned container image(s) do not comply with the selected policy. Visit Runecast UI for more details.')
                }

			}

            stage('Deploy') {
			    echo "Deploying container(s)"
			}

		} catch(e) {
			echo "${e.message}"
			currentBuild.result = "FAILED"
			throw e
		}
	}
}
