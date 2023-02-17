#!/bin/bash


# Constants
AUTH_URL="https://151dd0e4-bd8b-453b-a01c-924e75053a8b.mock.pstmn.io/auth"
PARAMETERS_URL="https://151dd0e4-bd8b-453b-a01c-924e75053a8b.mock.pstmn.io/parameters"
DEPLOYMENT_FILE="deployment.yaml"
LOG_FILE="deployment.log"

function log(){
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}


# Function to check if a command is installed and install it if it is not
function check_command() {
  local command_name="$1"
  if ! command -v "$command_name" > /dev/null 2>&1; then
    log "Installing $command_name"
    if [ -x "$(command -v apt-get)" ]; then
      if sudo apt-get update -y && sudo apt-get install -y "$command_name"; then
        log "$command_name installed successfully"
      else
        log "Failed to install $command_name package. Please install it manually and try again."
        exit 1
      fi
    elif [ -x "$(command -v yum)" ]; then
      if sudo yum install -y "$command_name" ; then
        log "$command_name installed successfully"
      else
        log "Failed to install $command_name package. Please install it manually and try again."
        exit 1
      fi
    else
      log "Error: Unable to install $command_name. Please install it manually."
      exit 1
    fi
  fi
}


# Function to get the authentication token
get_auth_token() {
  local url="$1"

  # Check if curl is installed
  check_command "curl"
  # Make API call and get authentication token
  local token=$(curl -s -X GET "$url")

  # Check if token is empty
  if [ -z "$token" ]; then
    log "Error: Failed to retrieve token from API"
    exit 1
  fi
  echo "$token"
}

# Function to get the parameters
get_parameters() {
  local url="$1"
  local token="$2"


  check_command "curl"
  check_command "jq"

  # Make second API call to retrieve parameters
  local response=$(curl -s -X GET "${url}?TOKEN=${token}")
  local curl_exit_code=$?
  if [[ $curl_exit_code -ne 0 ]]; then
    log "Error: curl command failed with exit code $curl_exit_code"
    exit 1
  fi

  # Parse the JSON response using jq
  local param1=$(echo "$response" | jq -r '.PARAMETER1' 2>/dev/null)
  local jq_exit_code=$?
  if [[ $jq_exit_code -ne 0 ]]; then
    log "Error: Failed to parse response with jq."
    exit 1
  fi

  local param2=$(echo "$response" | jq -r '.PARAMETER2' 2>/dev/null)
  jq_exit_code=$?
  if [[ $jq_exit_code -ne 0 ]]; then
    log "Error: Failed to parse response with jq."
    exit 1
  fi

  # Check if parameters are empty
  if [[ -z "$param1" || -z "$param2" ]]; then
    log "Error: Failed to retrieve parameters"
    exit 1
  fi

  # Return the values as a comma-separated string
  echo "${param1},${param2}"
}

# Function to create the deployment YAML file
function create_deployment_file() {
  local param1=$1
  local param2=$2

  # Generate the deployment YAML file
  cat <<EOF > $DEPLOYMENT_FILE
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: ubuntu
        command: ["/bin/sh"]
        args: ["-c", "echo HELLO WORLD, $param1 - $param2"]
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
  if [ -e "$DEPLOYMENT_FILE" ]; then
    log "Deployment file is created successfully."
  else
    log "Error : There was an error creating the file."
    exit 1
  fi

}

function apply_deployment() {
  check_command "kubectl"
  current_context=$(kubectl config current-context)
  if [ -z "$current_context" ]; then
    log "Error : It seems kubectl is not configure and unable to fetch cluster information. Please validate"
  fi

  log "Deploying in cluster : $current_context" 
  # Apply the deployment YAML file to your Kubernetes cluster
  output="$(kubectl apply -f ${DEPLOYMENT_FILE} 2>&1)" 
  if [ $? -eq 0 ]; then
    log "Deployment successful"
    log "$output"
  else
    log "Deployment failed please check logs for detail"
    log "$output"
    exit 1
  fi
}


log "Calling get auth token"
auth_token=$(get_auth_token "$AUTH_URL")
if [ $? -ne 0 ]; then
  log "Failed to get authentication token"
  echo "$auth_token"
else
  log "Auth token recieved initiating get parameter request"
  # Call the function to retrieve the parameters
  params=$(get_parameters "$PARAMETERS_URL" "$auth_token")
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to retrieve parameters"
    echo "$params"
  else
    log "Parameters recieved"
    # Split the returned string into separate variables
    if ! IFS=',' read -r param1 param2 <<< "$params"; then
      log "Error: failed to split parameters into variables."
      exit 1
    fi

    log "Creating deployment file"
    # Create the deployment YAML file
    if create_deployment_file "$param1" "$param2"; then  
      log "Calling deploymnet function"
      # Apply the deployment to the cluster
      apply_deployment
    fi
  fi
fi
