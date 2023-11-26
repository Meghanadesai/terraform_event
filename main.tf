provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "md-unique-bucket-name"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

terraform {
  backend "s3" {
    bucket = "bucket-tf4"
    key    = "path/to/my/key"
    region = "us-west-2"
  }
}


resource "aws_sns_topic" "topic" {
  name = "my-sns-topic"
}

resource "aws_sns_topic_policy" "my_sns_topic_policy" {
  arn    = aws_sns_topic.topic.arn
  policy = <<EOF
 {
	"Version": "2012-10-17",
	"Id": "__default_policy_ID",
 
  "Statement": [
    {
      "Sid": "Allow-SNS-SendMessage",
      "Effect": "Allow",
      "Principal": {
         "Service": "s3.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.topic.arn}",
	  "Condition": {
        "ArnLike": {
          "aws:SourceArn": "${aws_s3_bucket.bucket.arn}"
        }
      }
    },
    {
      "Sid": "Allow-User-GetTopicAttributes",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::439148720403:user/new-user"
      },
      "Action": "sns:GetTopicAttributes",
      "Resource": "${aws_sns_topic.topic.arn}"
    }
  ]
}
EOF
}

resource "aws_sqs_queue" "queue" {
  name = "my-sqs-queue"
}


resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = <<EOF
{
 "Version": "2012-10-17",
 "Id": "example-ID",
 "Statement": [
 {
   "Sid": "Allow-SendMessage",
   "Effect": "Allow",
   "Principal": {
    "Service": "sns.amazonaws.com"
   },
   "Action": [
    "sqs:SendMessage",
    "sqs:SetQueueAttributes"
  ],
   "Resource": "${aws_sqs_queue.queue.arn}"
 }
 ]
}
EOF
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  topic {
    topic_arn = aws_sns_topic.topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# resource "aws_lambda_function" "lambda" {
#   filename      = "myapp-lambda.zip"
#   function_name = "lambda_function_name"
#   role          = aws_iam_role.iam_for_lambda.arn
#   handler       = "exports.test"

#   source_code_hash = filebase64sha256("./myapp-lambda.zip")

#   runtime = "java8"
# }

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<EOF
	{
	"Version": "2012-10-17",
	"Statement": [
	{
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::439148720403:user/new-user"
      },
    "Action": ["s3:*"],
    "Resource": [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
 ]
}
EOF
}

resource "aws_iam_user" "user" {
  name = "user-name"
}

# resource "aws_iam_role" "iam_for_lambda" {
#   name               = "iam_for_lambda"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }


resource "aws_iam_policy" "s3_policy" {
  name        = "s3-action-policy"
  description = "A test policy"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "s3:*"
     ],
     "Effect": "Allow",
     "Resource": "${aws_s3_bucket.bucket.arn}"
   }
 ]
}
EOF
}

# resource "aws_iam_user_policy" "lambda_policy" {
#  name = "lambda_policy"
#  user = "user-name"

#  policy = <<EOF
# {
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": "lambda:*",
#      "Resource": "*"
#    }
#  ]
# }
# EOF
# }

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
 topic_arn = aws_sns_topic.topic.arn
 protocol = "sqs"
 endpoint = aws_sqs_queue.queue.arn
}

# resource "aws_sns_topic_subscription" "sns_topic_subscription_lambda" {
#  topic_arn = aws_sns_topic.topic.arn
#  protocol = "lambda"
#  endpoint = aws_lambda_function.lambda.arn
# }


# resource "aws_lambda_permission" "allow_sns_invoke" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.topic.arn
# }

# resource "aws_cloudwatch_log_group" "lambda_log_group" {
#  name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"

#  tags = {
#   Environment = "production"
#   Application = "my_lambda_function"
#  }
