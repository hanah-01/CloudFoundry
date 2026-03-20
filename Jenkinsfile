pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = 'test'
        AWS_SECRET_ACCESS_KEY = 'test'
        AWS_DEFAULT_REGION    = 'us-east-1'

        AWS_S3_FORCE_PATH_STYLE = 'true'

        TF_DIR = 'terraform'
        TF_VAR_create_ec2 = 'false'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'SKIP_SECURITY_SCAN',
            defaultValue: false,
            description: 'Skip tfsec / Checkov security scans'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.GIT_BRANCH}"
            }
        }
        stage('Verify LocalStack & Setup Backend') {
            steps {
                sh '''
                    echo "Checking LocalStack health..."
                    for i in $(seq 1 12); do
if curl -sf http://host.docker.internal:4566/_localstack/health; then
                            echo "LocalStack is healthy!"

                            aws --endpoint-url=http://host.docker.internal:4566 s3 mb s3://devops-lab-tf-state || true
                            
                            exit 0
                        fi
                        echo "Waiting for LocalStack... attempt $i/12"
                        sleep 5
                    done
                    echo "ERROR: LocalStack is not running. Start it with: docker-compose up -d"
                    exit 1
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
                        sh 'tfsec ${TF_DIR} --no-colour || true'
                    }
                }
                stage('Checkov') {
                    steps {
                        sh 'checkov -d ${TF_DIR} --quiet --compact || true'
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check -recursive || true'
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return params.ACTION in ['plan', 'apply'] }
            }
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                dir("${TF_DIR}") {
                    input message: 'Are you sure you want to DESTROY all resources?', ok: 'Yes, destroy'
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Verify Resources') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                sh '''
                    echo "=== S3 Buckets ==="
                    aws --endpoint-url=http://host.docker.internal:4566 s3 ls

                    echo "=== DynamoDB Tables ==="
                    aws --endpoint-url=http://host.docker.internal:4566 dynamodb list-tables

                    echo "=== Lambda Functions ==="
                    aws --endpoint-url=http://host.docker.internal:4566 lambda list-functions --query "Functions[].FunctionName"
                '''
            }
        }

    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
        always {
            echo "Pipeline finished. Action: ${params.ACTION}"
        }
    }
}