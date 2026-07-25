#!/usr/bin/groovy

def props

/** Use Jenkins AWS credential when aws_credentials_id is set; else ~/.aws/credentials profile. */
def jakshAws(Closure body) {
    def credId = env.AWS_CREDENTIALS_ID?.trim()
    def profile = env.AWS_PROFILE ?: 'jakshwealth'
    def awsEnv = [
        "AWS_DEFAULT_REGION=${env.AWS_REGION}",
        "AWS_REGION=${env.AWS_REGION}",
        "AWS_PROFILE=${profile}"
    ]

    if (credId) {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: credId,
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
            withEnv(awsEnv) {
                sh """
                    mkdir -p "\${HOME}/.aws"
                    cat > "\${HOME}/.aws/credentials" <<EOF
[${profile}]
aws_access_key_id=\${AWS_ACCESS_KEY_ID}
aws_secret_access_key=\${AWS_SECRET_ACCESS_KEY}
EOF
                """
                body()
            }
        }
    } else {
        withEnv(awsEnv) {
            body()
        }
    }
}

pipeline {
    agent any

    parameters {
        choice(
            name: 'TERRAFORM_ACTION',
            choices: ['apply', 'plan'],
            description: 'Terraform action for JakshWealth platform infra (UI hosting + API Gateway shell).'
        )
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Set environment') {
            steps {
                script {
                    props = readProperties file: "${WORKSPACE}/.cicd/build_props/build.properties"
                    env.AWS_CREDENTIALS_ID = (props.aws_credentials_id ?: '').trim()
                    env.AWS_PROFILE = props.aws_profile ?: 'jakshwealth'
                    env.AWS_REGION = props.aws_region ?: 'us-east-1'
                    env.DEPLOY_ENV = props.deploy_env ?: 'dev'
                }
            }
        }

        stage('Verify AWS credentials') {
            steps {
                script {
                    jakshAws {
                        sh 'aws sts get-caller-identity'
                    }
                }
            }
        }

        stage('Bootstrap foundation buckets') {
            when {
                expression { params.TERRAFORM_ACTION == 'apply' }
            }
            steps {
                script {
                    jakshAws {
                        sh '''
                            cd bootstrap/terraform
                            terraform init -input=false
                            chmod +x import-existing.sh
                            ./import-existing.sh "${DEPLOY_ENV}" terraform-state-lock
                            terraform apply -auto-approve \
                              -var-file="vars.dev.tfvars" \
                              -var="deploy_env=${DEPLOY_ENV}"
                        '''
                    }
                }
            }
        }

        stage('UI hosting (S3 + CloudFront)') {
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5

                            cd s3-cloudfront-ssa/module
                            terraform init -backend-config="config/dev-backend.tfvars"
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                              terraform apply -auto-approve -lock-timeout=10m \
                                -var "deploy_env=${DEPLOY_ENV}" \
                                -var-file="s3_config_vars/s3.dev.tfvars"
                            else
                              terraform plan -lock-timeout=10m \
                                -var "deploy_env=${DEPLOY_ENV}" \
                                -var-file="s3_config_vars/s3.dev.tfvars"
                            fi
                        '''
                    }
                }
            }
        }

        stage('API Gateway platform') {
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5

                            cd code-infra/module/main
                            terraform init -backend-config="backend.dev.tfvars"
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                              terraform apply -auto-approve -lock-timeout=10m -var-file="vars.dev.tfvars"
                            else
                              terraform plan -lock-timeout=10m -var-file="vars.dev.tfvars"
                            fi
                        '''
                    }
                }
            }
        }
    }
}
