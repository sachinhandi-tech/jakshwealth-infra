{
    "Version": "2012-10-17",
    "Id": "jakshwealth-ui-bucket-policy",
    "Statement": [
        {
            "Sid": "Stmt1552079734001",
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
        },
        {
            "Sid": "Allow Cloudfront to access S3 bucket",
            "Effect": "Allow",
            "Principal": {
                "AWS": ${cloudfront_OAI}
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
             ],
            "Resource": ${bucket_resources}
        }
    ]
}
