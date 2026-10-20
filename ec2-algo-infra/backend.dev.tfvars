# Keep this key. Renaming it makes the next apply create a second copy of the stack.
bucket                 = "jakshwealth-infra-dev-aps2"
key                    = "dev/parallel-nse-scan/terraform.tfstate"
region                 = "ap-south-2"
dynamodb_table         = "terraform-state-lock"
profile                = "jakshwealth"
skip_region_validation = true
