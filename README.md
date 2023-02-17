# Swisscom SminGate Coding Challenge CI/CD

## Background
The "Hello World" application is running in Kubernetes and requires additional parameters from an external data source, which can be retrieved via an API. The API requires an authentication request, providing a token, authorizing subsequent query requests. 

The objective of this task is to create an automation, which authenticates against the API of the external data source, retrieves the parameters, and deploys the "Hello World" application including the retrieved data to Kubernetes.

## Tasks
Part 1 involves creating the automation given specific presets. Part 2 involves critacally questioning the presets.

### 1.
* Create a Bash script which retrieves the token for the external data source API, then retrieves PARAMETER1 and PARAMETER2, passing the token via http GET parameter named 'TOKEN'. 
* Create a docker image, ready to run this bash script.
* Extend the Bash script to generate a plain kubernetes deployment yaml, deploying the "Hello World" app. The provided deployment must result in the container outputting "HELLO WORD , {parmater1} - {parmater1}" on startup, with the retrieved values of PARAMETER1 and PARAMETER2.

### 2.
* Please come up with an alternative way to deploy the "Hello World" application with the same end result as with part 1, then briefly debate the pros and cons of both solutions.
* Please note: it is not required to create a demonstration of the alternative solution.

> **Important:** To ensure your privacy, please **download** the Github repository and submit your work in your own Github repository. Once finished, kindly send us the link to the repository for review.

## Resources
* Hello World app: https://hub.docker.com/_/hello-world
* external data source auth: https://151dd0e4-bd8b-453b-a01c-924e75053a8b.mock.pstmn.io/auth
* external data source parameters: https://151dd0e4-bd8b-453b-a01c-924e75053a8b.mock.pstmn.io/parameters


## Solution

### 1.
## Script details
* Bash script is created that will make two get request one to get auth and second for parameters and then create a deployment.yaml
* Script will use curl, jq and kubectl command it will try to install if not available.
* Script assume .kube configuration are alredy done on the cluster and cluster has access to dockerhub.
* Script will produce a deploymen.yaml file for kubernetes deployment and a deployment.log for all logs in same directory.

### 2.
## Other Solutions
* There could be multiple solutions and variations for this kind of issues.
* If the auth and parameters will remain same then we can move them to secret for kubernets instead of doing multiple api calls.
* We can make our custom image and make it to accept env variable and pass parameters as environment variable. Then we dont have to create deployment.yaml everytime we can just set values for variables.
* If application need to execute only few line and then finished then we can move itto a job instead of deployment.
* My prefered solutioin would be creating an init container that will fetch the parameter and do all other stuff then put required values in sared volume. After it successfully executed main container will run and get those values from volume and do its work. In this way we dont have to manage kubernetes and script at one place.

