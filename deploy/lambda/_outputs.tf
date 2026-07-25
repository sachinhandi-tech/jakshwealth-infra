output "lambda_id" {
  description = "The ID of the lambda that was created."
  value = aws_lambda_function.lambda.id
}

output "name" {
  value = aws_lambda_function.lambda.function_name
}

output "arn" {
  value = aws_lambda_function.lambda.arn
}