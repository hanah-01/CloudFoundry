pipeline {
    agent any

    options {
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'LOCAL_ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'LocalStack Terraform action'
        )
        booleanParam(
            name: 'RUN_PROD',
            defaultValue: false,
            description: 'Run real AWS production stage (student-tier friendly defaults)'
        )
        booleanParam(
            name: 'SKIP_SECURITY_SCAN',
            defaultValue: false,
            description: 'Skip tfsec / Checkov security scans'
        )
        booleanParam(
            name: 'DESTROY_AFTER_BUILD',
            defaultValue: true,
            description: 'Destroy LocalStack resources after pipeline'
        )
    }

    environment {
        TF_IN_AUTOMATION    = 'true'
        TF_CLI_ARGS         = '-no-color'

        AWS_REGION = 'us-east-1'
        LOCALSTACK_NAME     = 'localstack'
        LOCALSTACK_IMAGE    = 'localstack/localstack:3.0'
        DOCKER_NET          = 'devopsnet'
        TF_PLUGIN_CACHE_DIR = '/var/jenkins_home/.terraform.d/plugin-cache'

        LOCAL_TF_DIR        = 'terraform/environments/local'
        PROD_TF_DIR         = 'terraform/environments/prod'
        DESTROY_AFTER_BUILD = "${params.DESTROY_AFTER_BUILD}"

    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.GIT_BRANCH}"
            }
        }

        stage('System Diagnostics') {
            steps {
                sh '''#!/bin/sh
                echo "=== Disk Usage ==="
                df -h
                echo "=== Docker Info ==="
                docker info
                echo "=== Cleaning Docker System ==="
                docker system prune -af --volumes || true
                '''
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''#!/bin/sh
                echo "LOCALSTACK_IMAGE=$LOCALSTACK_IMAGE"
                aws --version || (echo "AWS CLI missing" && exit 1)
                terraform version
                docker version
                ls -R /tf
                '''
            }
        }

        stage('Ensure Network Connectivity') {
            steps {
                sh '''#!/bin/sh
                docker network create "$DOCKER_NET" || true
                docker network connect "$DOCKER_NET" jenkins || true
                docker network connect "$DOCKER_NET" "$LOCALSTACK_NAME" || true
                curl -s --max-time 3 http://localstack:4566/_localstack/health || echo "Direct connectivity check failed, but continuing..."
                '''
            }
        }

        stage('Prepull LocalStack') {
            steps {
                sh 'docker image inspect "$LOCALSTACK_IMAGE" >/dev/null 2>&1 || docker pull "$LOCALSTACK_IMAGE"'
            }
        }

        stage('Verify LocalStack Connectivity') {
            steps {
                sh '''#!/bin/sh
                echo "Waiting for LocalStack to be ready..."
                MAX_RETRIES=30
                COUNT=0
                until curl -s http://localstack:4566/_localstack/health >/dev/null || [ $COUNT -eq $MAX_RETRIES ]; do
                  echo "Waiting for LocalStack... ($((COUNT+1))/$MAX_RETRIES)"
                  sleep 2
                  COUNT=$((COUNT+1))
                done

                if [ $COUNT -eq $MAX_RETRIES ]; then
                  echo "LocalStack failed to become ready in time"
                  exit 1
                fi
                echo "LocalStack is ready"
                '''
            }
        }

        stage('Security Scan') {
            when {
                expression { return !params.SKIP_SECURITY_SCAN }
            }
            parallel {
                stage('tfsec') {
                    steps {
                        sh 'docker run --rm --network "$DOCKER_NET" -v "$WORKSPACE":/tf aquasec/tfsec /tf/${LOCAL_TF_DIR} --no-colour || true'
                    }
                }
                stage('Checkov') {
                    steps {
                        sh '''
        docker run --rm \
        --network "$DOCKER_NET" \
        -v "$WORKSPACE":/tf \
        bridgecrew/checkov \
        -d /tf/terraform/environments/local \
        --framework terraform \
        --quiet || true
        '''
                    }
                }

                stage('Trivy') {
                    steps {
                        sh '''
docker run --rm \
--network "$DOCKER_NET" \
-v /var/run/docker.sock:/var/run/docker.sock \
aquasec/trivy:latest image docker-jenkins || true
'''
                    }
                }
            }
        }

        stage('LocalStack Validation') {
            steps {
                sh '''#!/bin/sh
set -eu
export TF_VAR_localstack_endpoint=http://localstack:4566
export TF_VAR_enable_compute=false
export TF_VAR_enable_self_healing=false
export TF_VAR_enable_load_balancer=false
cd "$LOCAL_TF_DIR"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

if [ ! -f "backend.localstack.hcl" ]; then
  echo "bucket = \\"localstack-terraform-state\\"" > backend.localstack.hcl
  echo "key = \\"devops/local/terraform.tfstate\\"" >> backend.localstack.hcl
  echo "region = \\"us-east-1\\"" >> backend.localstack.hcl
  echo "endpoints = { s3 = \\"http://localstack:4566\\" }" >> backend.localstack.hcl
  echo "use_path_style = true" >> backend.localstack.hcl
  echo "skip_credentials_validation = true" >> backend.localstack.hcl
  echo "skip_metadata_api_check = true" >> backend.localstack.hcl
  echo "skip_region_validation = true" >> backend.localstack.hcl
  echo "skip_requesting_account_id = true" >> backend.localstack.hcl
fi

# Ensure bucket exists
AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws --endpoint-url=http://localstack:4566 --no-cli-pager s3 mb s3://localstack-terraform-state || true

terraform init -input=false -backend-config=backend.localstack.hcl
terraform plan -input=false -out=tfplan
if [ "${LOCAL_ACTION}" = "apply" ]; then
  terraform apply -input=false -auto-approve tfplan
elif [ "${LOCAL_ACTION}" = "destroy" ]; then
  terraform destroy -input=false -auto-approve || true
fi
'''
            }
        }

        stage('Integration Tests (LocalStack)') {
            when {
                expression { return params.LOCAL_ACTION == 'apply' }
            }
            steps {
                sh '''#!/bin/sh
set -eu
echo ">>> Running Integration Tests..."
export AWS_PAGER=""
export AWS_ACCESS_KEY_ID=test 
export AWS_SECRET_ACCESS_KEY=test 
export AWS_DEFAULT_REGION=us-east-1

echo "1. Creating test file..."
echo "Hello from Jenkins Serverless Test" > test-artifact.txt

echo "2. Uploading to S3..."
aws --endpoint-url=http://localstack:4566 --no-cli-pager s3 cp test-artifact.txt s3://devops-lab-artifacts-bucket/ || true

echo "3. Waiting 10 seconds for Lambda & DynamoDB triggers to fully process..."
sleep 10

echo "4. Scanning DynamoDB Metadata Table for created artifact..."
aws --endpoint-url=http://localstack:4566 --no-cli-pager dynamodb scan --table-name devops-lab-artifacts-metadata

echo ">>> End of Tests. If you see items in DynamoDB above, the flow S3 -> Lambda -> DynamoDB worked perfectly!"
'''
            }
        }

        stage('AWS Deploy (Prod)') {
            when {
                allOf {
                    expression { return params.RUN_PROD }
                    expression { env.CHANGE_ID == null }
                    anyOf {
                        branch 'main'
                    }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'TF_BACKEND_BUCKET', variable: 'TF_BACKEND_BUCKET'),
                    string(credentialsId: 'PROD_AMI_ID', variable: 'PROD_AMI_ID')
                ]) {
                    sh '''#!/bin/sh
set -eu

: "${AWS_ACCESS_KEY_ID:?Set AWS_ACCESS_KEY_ID in Jenkins credentials}"
: "${AWS_SECRET_ACCESS_KEY:?Set AWS_SECRET_ACCESS_KEY in Jenkins credentials}"
: "${PROD_AMI_ID:?Set PROD_AMI_ID for production launch template}"

BACKEND_ARGS=""
if [ -f "$PROD_TF_DIR/backend.hcl" ]; then
  BACKEND_ARGS="-backend-config=backend.hcl"
elif [ -n "${TF_BACKEND_BUCKET:-}" ]; then
  TF_BACKEND_KEY="${TF_BACKEND_KEY:-devops/prod/terraform.tfstate}"
  TF_BACKEND_REGION="${TF_BACKEND_REGION:-$AWS_REGION}"
  BACKEND_ARGS="-backend-config=bucket=${TF_BACKEND_BUCKET} -backend-config=key=${TF_BACKEND_KEY} -backend-config=region=${TF_BACKEND_REGION}"
  if [ -n "${TF_BACKEND_DYNAMODB_TABLE:-}" ]; then
    BACKEND_ARGS="$BACKEND_ARGS -backend-config=dynamodb_table=${TF_BACKEND_DYNAMODB_TABLE}"
  fi
fi

export TF_VAR_ami_id="$PROD_AMI_ID"
export TF_VAR_enable_compute=true
export TF_VAR_enable_self_healing=false
export TF_VAR_enable_load_balancer=false
export TF_VAR_desired_capacity=1
export TF_VAR_min_size=1
export TF_VAR_max_size=1
export TF_VAR_localstack_mode=false

cd "$PROD_TF_DIR"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
terraform init -input=false ${BACKEND_ARGS}
terraform plan -input=false -out=tfplan
terraform apply -input=false -auto-approve tfplan
terraform output -raw alb_dns_name > ../../../prod_alb_dns_name.txt || true
'''
                                }
            }
        }
    }

    post {
        always {
            sh '''#!/bin/sh
set +e
docker network inspect "$DOCKER_NET" >/dev/null 2>&1 || docker network create "$DOCKER_NET" >/dev/null 2>&1

export TF_VAR_enable_compute=false
export TF_VAR_enable_self_healing=false
export TF_VAR_enable_load_balancer=false

cd "$LOCAL_TF_DIR"
if [ -d .terraform ] && [ "${DESTROY_AFTER_BUILD}" = "true" ]; then
  terraform destroy -input=false -auto-approve || true
fi
'''
        }

        success {
            script {
                if ((env.BRANCH_NAME == 'main') && fileExists('prod_alb_dns_name.txt')) {
                    def albDns = readFile('prod_alb_dns_name.txt').trim()
                    if (albDns) {
                        echo "Production ALB URL: http://${albDns}"
                    }
                }
            }
        }
    }
}
