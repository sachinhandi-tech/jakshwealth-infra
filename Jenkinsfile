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
            choices: ['plan', 'apply', 'destroy'],
            description: 'plan or apply builds the UI, the database, then the API. destroy removes the API, the database, the UI, then the foundation buckets.'
        )
    }
    environment {
        TF_PLUGIN_CACHE_DIR = "${env.HOME}/.terraform.d/plugin-cache"
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
                    env.AWS_REGION = props.aws_region ?: 'ap-south-2'
                    env.DEPLOY_ENV = props.deploy_env ?: 'dev'
                }
            }
        }
        
        stage('Free disk for Terraform providers') {
            steps {
                sh '''
                    echo "Disk before cleanup:"
                    df -h "${WORKSPACE}"
                    find "${WORKSPACE}" -type d -name .terraform -prune -exec rm -rf {} +
                    mkdir -p "${TF_PLUGIN_CACHE_DIR}"
                    echo "Disk after removing workspace provider copies:"
                    df -h "${WORKSPACE}"
                    
                    avail_kb=$(df -Pk "${WORKSPACE}" | awk 'NR==2 {print $4}')
                    if [ "${avail_kb}" -lt 800000 ]; then
                        echo "Less than 800MB is free. Old Jenkins workspaces are still filling the disk."
                        du -xh --max-depth 2 "${HOME}/workspace" 2>/dev/null | sort -h | tail -n 20 || true
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Verify AWS credentials') {
            steps {
                script {
                    jakshAws {
                        sh '''
                            terraform version
                            aws sts get-caller-identity
                        '''
                    }
                }
            }
        }
        
        stage('Bootstrap foundation buckets') {
            when { expression { params.TERRAFORM_ACTION == 'apply' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            cd bootstrap/terraform
                            terraform init -input=false
                            chmod +x import-existing.sh
                            ./import-existing.sh "${DEPLOY_ENV}" terraform-state-lock
                            terraform apply -auto-approve -var-file="vars.dev.tfvars" -var="deploy_env=${DEPLOY_ENV}"
                        '''
                    }
                }
            }
        }
        
        stage('UI hosting (S3 + CloudFront)') {
            when { expression { params.TERRAFORM_ACTION != 'destroy' } }
            steps {
                catchError(buildResult: null, stageResult: 'FAILURE') {
                    script {
                        jakshAws {
                            sh '''
                                chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                                REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5
                                
                                cd s3-cloudfront-ui/module
                                terraform init -input=false -reconfigure -backend-config="config/dev-backend.tfvars"
                                
                                if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                                    terraform apply -auto-approve -lock-timeout=10m -var "deploy_env=${DEPLOY_ENV}" -var-file="s3_config_vars/s3.dev.tfvars"
                                elif [ "${TERRAFORM_ACTION}" = "destroy" ]; then
                                    terraform destroy -auto-approve -lock-timeout=10m -var "deploy_env=${DEPLOY_ENV}" -var-file="s3_config_vars/s3.dev.tfvars"
                                else
                                    terraform plan -lock-timeout=10m -var "deploy_env=${DEPLOY_ENV}" -var-file="s3_config_vars/s3.dev.tfvars"
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Subscriber Postgres') {
            when { expression { params.TERRAFORM_ACTION != 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5
                            
                            cd postgres
                            terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"
                            
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                                terraform apply -auto-approve -lock-timeout=15m -var-file="vars.dev.tfvars"
                            elif [ "${TERRAFORM_ACTION}" = "destroy" ]; then
                                terraform destroy -auto-approve -lock-timeout=15m -var-file="vars.dev.tfvars"
                            else
                                terraform plan -lock-timeout=15m -var-file="vars.dev.tfvars"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('EC2 algo infra') {
            when { expression { params.TERRAFORM_ACTION != 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5
                            
                            cd ec2-algo-infra
                            terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"
                            
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                                terraform apply -auto-approve -lock-timeout=10m
                                
                                # Force rolling update of ASG to apply new Nginx config
                                ASG_NAME=$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "")
                                if [ -n "${ASG_NAME}" ] && [ "${ASG_NAME}" != "None" ]; then
                                    echo "Triggering rolling update for ASG: ${ASG_NAME}"
                                    aws autoscaling start-instance-refresh --auto-scaling-group-name "${ASG_NAME}" --region "${AWS_REGION}" || echo "Rolling update may have already been triggered"
                                    
                                    echo "Waiting for rolling update to complete..."
                                    aws autoscaling describe-instance-refreshes --auto-scaling-group-name "${ASG_NAME}" --region "${AWS_REGION}" --query "InstanceRefreshes[0].Status" --output text || echo "Could not check refresh status"
                                fi
                                
                                # Invalidate CloudFront cache after EC2 infra update
                                CF_ID=$(terraform output -raw api_cloudfront_id 2>/dev/null || echo "")
                                if [ -n "${CF_ID}" ] && [ "${CF_ID}" != "None" ]; then
                                    echo "Invalidating CloudFront distribution: ${CF_ID}"
                                    aws cloudfront create-invalidation --distribution-id "${CF_ID}" --paths "/*" --query "Invalidation.Id" --output text
                                    echo "CloudFront invalidation completed"
                                else
                                    echo "No CloudFront distribution ID found, skipping invalidation"
                                fi
                                
                            else
                                terraform plan -lock-timeout=10m
                            fi
                        '''
                    }
                }
            }
        }

        stage('Destroy API (EC2)') {
            when { expression { params.TERRAFORM_ACTION == 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5

                            cd ec2-algo-infra
                            terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"

                            ok=0
                            for attempt in 1 2 3 4 5 6 7 8; do
                                if terraform destroy -auto-approve -lock-timeout=10m; then
                                    ok=1
                                    break
                                fi
                                echo "API destroy attempt ${attempt} failed. Waiting for network interfaces to release."
                                sleep 90
                            done
                            if [ "${ok}" != "1" ]; then
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('Destroy Postgres') {
            when { expression { params.TERRAFORM_ACTION == 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5

                            cd postgres
                            terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"

                            if terraform state list | grep -q .; then
                                terraform apply -auto-approve -lock-timeout=15m -var-file="vars.dev.tfvars" \
                                    -var="deletion_protection=false" \
                                    -var="skip_final_snapshot=true" \
                                    -var="secret_recovery_window_in_days=0"
                            fi
                            terraform destroy -auto-approve -lock-timeout=15m -var-file="vars.dev.tfvars" \
                                -var="deletion_protection=false" \
                                -var="skip_final_snapshot=true" \
                                -var="secret_recovery_window_in_days=0"

                            aws secretsmanager delete-secret \
                                --secret-id "jakshwealth/${DEPLOY_ENV}/jakshwealth" \
                                --force-delete-without-recovery \
                                --region "${AWS_REGION}" || true
                            aws rds delete-db-snapshot \
                                --db-snapshot-identifier "jakshwealth-${DEPLOY_ENV}-postgres-final" \
                                --region "${AWS_REGION}" || true
                        '''
                    }
                }
            }
        }

        stage('Destroy UI') {
            when { expression { params.TERRAFORM_ACTION == 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            chmod +x "${WORKSPACE}/scripts/terraform-unlock-stale.sh"
                            REMOVE_NON_JENKINS=1 "${WORKSPACE}/scripts/terraform-unlock-stale.sh" 5

                            cd s3-cloudfront-ui/module
                            terraform init -input=false -reconfigure -backend-config="config/dev-backend.tfvars"
                            terraform destroy -auto-approve -lock-timeout=10m -var "deploy_env=${DEPLOY_ENV}" -var-file="s3_config_vars/s3.dev.tfvars"
                        '''
                    }
                }
            }
        }

        stage('Destroy foundation buckets') {
            when { expression { params.TERRAFORM_ACTION == 'destroy' } }
            steps {
                script {
                    jakshAws {
                        sh '''
                            case "${AWS_REGION}" in
                                ap-south-2) suffix=aps2 ;;
                                us-east-1) suffix=use1 ;;
                                *) suffix=$(printf '%s' "${AWS_REGION}" | tr -d '-') ;;
                            esac

                            purge_bucket() {
                                bucket="$1"
                                if ! aws s3api head-bucket --bucket "${bucket}" >/dev/null 2>&1; then
                                    echo "Already gone: ${bucket}"
                                    return 0
                                fi
                                echo "Emptying ${bucket}"
                                while true; do
                                    payload=$(aws s3api list-object-versions --bucket "${bucket}" --max-keys 1000 --output json | python3 -c '
import json, sys
data = json.load(sys.stdin)
items = (data.get("Versions") or []) + (data.get("DeleteMarkers") or [])
objects = [{"Key": item["Key"], "VersionId": item["VersionId"]} for item in items]
print(json.dumps({"Objects": objects, "Quiet": True}) if objects else "")
')
                                    if [ -z "${payload}" ]; then
                                        break
                                    fi
                                    aws s3api delete-objects --bucket "${bucket}" --delete "${payload}" >/dev/null
                                done
                                aws s3api delete-bucket --bucket "${bucket}"
                                echo "Deleted ${bucket}"
                            }

                            purge_bucket "jakshwealth-infra-${DEPLOY_ENV}-${suffix}"
                            purge_bucket "jakshwealth-artifacts-${DEPLOY_ENV}-${suffix}"
                            purge_bucket "jakshwealth-logs-${DEPLOY_ENV}-${suffix}"
                            aws dynamodb delete-table --table-name terraform-state-lock --region "${AWS_REGION}" || true
                        '''
                    }
                }
            }
        }
    }
}
