{
    "Version": "2012-10-17",
    "Id": "jakshwealth-ui-bucket-policy",
    "Statement": [
        {
            "Sid": "AllowAccountOwner",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:root"
            },
            "Action": "s3:*",
            "Resource": ${bucket_resources}
        },
        {
            "Sid": "AllowDeployUsers",
            "Effect": "Allow",
            "Principal": {
                "AWS": ${key_users}
            },
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "s3:Delete*"
            ],
            "Resource": ${bucket_resources}
        }%{ if length(jsondecode(cloudfront_OAI)) > 0 ~},
        {
            "Sid": "AllowCloudFrontOAI",
            "Effect": "Allow",
            "Principal": {
                "AWS": ${cloudfront_OAI}
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": ${bucket_resources}
        }%{ endif ~}%{ if public_read ~},
        {
            "Sid": "AllowPublicReadForWebsiteOrigin",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": ${bucket_resources}
        }%{ endif ~}
    ]
}
