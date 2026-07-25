#!/usr/bin/groovy

pipeline {
    agent any

    options {
        ansiColor('xterm')
        timestamps()
    }

    parameters {
        choice(
            name: 'TERRAFORM_ACTION',
            choices: ['apply', 'plan'],
            description: 'Terraform action for JakshWealth platform infra'
        )
    }

    environment {
        DEPLOY_ENV = "${env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' ? 'prod' : (env.BRANCH_NAME == 'test' ? 'test' : 'dev')}"
    }

    stages {
        stage('Verify AWS credentials') {
            steps {
                sh """
                    export AWS_PROFILE=\${AWS_PROFILE:-jakshwealth}
                    aws sts get-caller-identity
                """
            }
        }

        stage('UI hosting (S3 + CloudFront)') {
            steps {
                sh """
                    export AWS_PROFILE=\${AWS_PROFILE:-jakshwealth}
                    cd ${WORKSPACE}/s3-cloudfront-ssa/module
                    terraform init -backend-config=config/${DEPLOY_ENV}-backend.tfvars
                    terraform ${params.TERRAFORM_ACTION} -var deploy_env=${DEPLOY_ENV} -var-file=s3_config_vars/s3.${DEPLOY_ENV}.tfvars
                """
            }
        }

        stage('API Gateway platform') {
            steps {
                sh """
                    export AWS_PROFILE=\${AWS_PROFILE:-jakshwealth}
                    cd ${WORKSPACE}/code-infra/module/main
                    terraform init -backend-config=backend.${DEPLOY_ENV}.tfvars
                    terraform ${params.TERRAFORM_ACTION} -var-file=vars.${DEPLOY_ENV}.tfvars
                """
            }
        }
    }
}
