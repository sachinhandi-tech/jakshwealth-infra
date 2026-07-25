#!/usr/bin/groovy

def props

def jakshAws(Closure body) {
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: 'jakshwealth-aws',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
    ]]) {
        withEnv([
            "AWS_DEFAULT_REGION=${env.AWS_REGION}",
            "AWS_REGION=${env.AWS_REGION}",
            'AWS_PROFILE=jakshwealth'
        ]) {
            sh '''
                mkdir -p "${HOME}/.aws"
                cat > "${HOME}/.aws/credentials" <<EOF
[jakshwealth]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
EOF
            '''
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
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        props = readProperties file: "${WORKSPACE}/.cicd/build_props/prod-build.properties"
                    } else if (env.BRANCH_NAME == 'test') {
                        props = readProperties file: "${WORKSPACE}/.cicd/build_props/test-build.properties"
                    } else {
                        props = readProperties file: "${WORKSPACE}/.cicd/build_props/dev-build.properties"
                    }
                    env.AWS_CREDENTIALS_ID = props.aws_credentials_id ?: 'jakshwealth-aws'
                    env.AWS_REGION = props.aws_region ?: 'us-east-1'
                    env.DEPLOY_ENV = props.deploy_env
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

        stage('UI hosting (S3 + CloudFront)') {
            steps {
                script {
                    jakshAws {
                        sh '''
                            cd s3-cloudfront-ssa/module
                            terraform init -backend-config="config/${DEPLOY_ENV}-backend.tfvars"
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                              terraform apply -auto-approve \
                                -var "deploy_env=${DEPLOY_ENV}" \
                                -var-file="s3_config_vars/s3.${DEPLOY_ENV}.tfvars"
                            else
                              terraform plan \
                                -var "deploy_env=${DEPLOY_ENV}" \
                                -var-file="s3_config_vars/s3.${DEPLOY_ENV}.tfvars"
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
                            cd code-infra/module/main
                            terraform init -backend-config="backend.${DEPLOY_ENV}.tfvars"
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                              terraform apply -auto-approve -var-file="vars.${DEPLOY_ENV}.tfvars"
                            else
                              terraform plan -var-file="vars.${DEPLOY_ENV}.tfvars"
                            fi
                        '''
                    }
                }
            }
        }
    }
}
