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
    }

    environment {
        TF_IN_AUTOMATION    = 'true'
        TF_CLI_ARGS         = '-no-color'

        AWS_REGION          = 'eu-north-1'
        LOCALSTACK_NAME     = 'localstack-ci'
        LOCALSTACK_IMAGE    = 'localstack/localstack:3.0'
        DOCKER_NET          = 'devopsnet'
        TF_PLUGIN_CACHE_DIR = '/workspace/.terraform.d/plugin-cache'

        LOCAL_TF_DIR        = 'terraform/environments/local'
        PROD_TF_DIR         = 'terraform/environments/prod'

        # AWS credentials are injected only in the prod stage.
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.GIT_BRANCH}"
            }
        }

        stage('Prepare LocalStack') {
            steps {
                sh '''#!/bin/sh
set -eu
docker network inspect "$DOCKER_NET" >/dev/null 2>&1 || docker network create "$DOCKER_NET"
docker rm -f "$LOCALSTACK_NAME" >/dev/null 2>&1 || true
'''
            }
        }

        stage('Start LocalStack') {
            steps {
                sh '''#!/bin/sh
set -eu
docker run -d --name "$LOCALSTACK_NAME" --network "$DOCKER_NET" --network-alias localstack \
  -e SERVICES=s3,iam,sts,lambda,dynamodb,cloudwatch,logs,apigateway \
  -e AWS_DEFAULT_REGION=$AWS_REGION \
  "$LOCALSTACK_IMAGE" >/dev/null
'''
            }
        }

        stage('Wait LocalStack Health') {
            steps {
                sh '''#!/bin/sh
set -eu
attempt=0
max_attempts=30
while [ "$attempt" -lt "$max_attempts" ]; do
  health_status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' "$LOCALSTACK_NAME" 2>/dev/null || echo unknown)"
  if [ "$health_status" = "healthy" ] && \
     docker run --rm --network "$DOCKER_NET" --entrypoint '' hashicorp/terraform:1.7.0 \
       sh -lc 'wget -q --spider http://localstack:4566/_localstack/health'; then
    echo "LocalStack is healthy"
    exit 0
  fi
  attempt=$((attempt + 1))
  echo "Waiting for LocalStack health (docker=${health_status}) attempt ${attempt}/${max_attempts}"
  sleep 2
done
echo "LocalStack did not become healthy in time"
docker logs --tail 120 "$LOCALSTACK_NAME" || true
exit 1
'''
            }
        }

        stage('Security Scan (Local)') {
            when {
                expression { return !params.SKIP_SECURITY_SCAN }
            }
            parallel {
                stage('tfsec') {
                    steps {
                        sh 'tfsec ${LOCAL_TF_DIR} --no-colour || true'
                    }
                }
                stage('Checkov') {
                    steps {
                        sh 'checkov -d ${LOCAL_TF_DIR} --quiet --compact || true'
                    }
                }
            }
        }

        stage('LocalStack Validation') {
            steps {
                sh '''#!/bin/sh
set -eu
docker run --rm --network "$DOCKER_NET" \
  -u "$(id -u):$(id -g)" \
  -v "$WORKSPACE":/workspace \
  -w "/workspace/$LOCAL_TF_DIR" \
  -e TF_IN_AUTOMATION=true \
  -e TF_PLUGIN_CACHE_DIR=/workspace/.terraform.d/plugin-cache \
    -e TF_VAR_localstack_endpoint=http://localstack:4566 \
  -e TF_VAR_enable_compute=false \
  -e TF_VAR_enable_self_healing=false \
  -e TF_VAR_enable_load_balancer=false \
  --entrypoint '' hashicorp/terraform:1.7.0 sh -lc '
    mkdir -p "$TF_PLUGIN_CACHE_DIR"
    terraform init -input=false -backend-config=backend.localstack.hcl
    terraform plan -input=false -out=tfplan
    if [ "${LOCAL_ACTION}" = "apply" ]; then
      terraform apply -input=false -auto-approve tfplan
    elif [ "${LOCAL_ACTION}" = "destroy" ]; then
      terraform destroy -input=false -auto-approve || true
    fi
  '
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
                        branch 'master'
                        branch 'temp-f'
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
if [ -f "$WORKSPACE/$PROD_TF_DIR/backend.hcl" ]; then
  BACKEND_ARGS="-backend-config=backend.hcl"
elif [ -n "${TF_BACKEND_BUCKET:-}" ]; then
  TF_BACKEND_KEY="${TF_BACKEND_KEY:-devops/prod/terraform.tfstate}"
  TF_BACKEND_REGION="${TF_BACKEND_REGION:-$AWS_REGION}"
  BACKEND_ARGS="-backend-config=bucket=${TF_BACKEND_BUCKET} -backend-config=key=${TF_BACKEND_KEY} -backend-config=region=${TF_BACKEND_REGION}"
  if [ -n "${TF_BACKEND_DYNAMODB_TABLE:-}" ]; then
    BACKEND_ARGS="$BACKEND_ARGS -backend-config=dynamodb_table=${TF_BACKEND_DYNAMODB_TABLE}"
  fi
fi

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$WORKSPACE":/workspace \
  -w "/workspace/$PROD_TF_DIR" \
  -e TF_IN_AUTOMATION=true \
  -e TF_PLUGIN_CACHE_DIR=/workspace/.terraform.d/plugin-cache \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_REGION \
  -e TF_VAR_ami_id="$PROD_AMI_ID" \
  -e TF_VAR_enable_compute=true \
  -e TF_VAR_enable_self_healing=false \
  -e TF_VAR_enable_load_balancer=false \
  -e TF_VAR_desired_capacity=1 \
  -e TF_VAR_min_size=1 \
  -e TF_VAR_max_size=1 \
  -e TF_VAR_localstack_mode=false \
  --entrypoint '' hashicorp/terraform:1.7.0 sh -lc "
    mkdir -p \"$TF_PLUGIN_CACHE_DIR\"
    terraform init -input=false ${BACKEND_ARGS}
    terraform plan -input=false -out=tfplan
    terraform apply -input=false -auto-approve tfplan
    terraform output -raw alb_dns_name > /workspace/prod_alb_dns_name.txt || true
  "
'''
                                }
            }
        }
    }

    post {
        always {
            sh '''#!/bin/sh
set +e
docker run --rm --network "$DOCKER_NET" \
  -u "$(id -u):$(id -g)" \
  -v "$WORKSPACE":/workspace \
  -w "/workspace/$LOCAL_TF_DIR" \
  -e TF_IN_AUTOMATION=true \
  -e TF_PLUGIN_CACHE_DIR=/workspace/.terraform.d/plugin-cache \
  -e TF_VAR_enable_compute=false \
  -e TF_VAR_enable_self_healing=false \
  -e TF_VAR_enable_load_balancer=false \
  --entrypoint '' hashicorp/terraform:1.7.0 sh -lc '
    mkdir -p "$TF_PLUGIN_CACHE_DIR"
    if [ -f terraform.tfstate ]; then
      terraform destroy -input=false -auto-approve || true
    fi
  ' || true

docker rm -f "$LOCALSTACK_NAME" >/dev/null 2>&1 || true
docker network rm "$DOCKER_NET" >/dev/null 2>&1 || true
'''
        }

        success {
            script {
                if ((env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master' || env.BRANCH_NAME=='temp-f') && fileExists('prod_alb_dns_name.txt')) {
                    def albDns = readFile('prod_alb_dns_name.txt').trim()
                    if (albDns) {
                        echo "Production ALB URL: http://${albDns}"
                    }
                }
            }
        }
    }
}
