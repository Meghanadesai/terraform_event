  provider "aws" {
    region = "us-west-2"
  }

  resource "aws_s3_bucket" "bucket" {
    bucket = "mdkm-bucket"

    tags = {
      Name       = "My bucket"
      Environment = "Dev"
    }
  }
  
terraform {
 backend "s3" {
   bucket = "terraform-bucket-state"
   key   = "path/to/my/key"
   region = "us-west-2"
 }
}


  resource "aws_sns_topic" "topic" {
     name = "my-sns-topic"
  }
  
  resource "aws_sns_topic_policy" "my_sns_topic_policy" {
	arn   = aws_sns_topic.topic.arn
	policy = <<POLICY
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
        "AWS": "arn:aws:iam::179500152044:user/new-user"
      },
      "Action": "SNS:GetTopicAttributes",
      "Resource": "${aws_sns_topic.topic.arn}"
    }
  ]
}
POLICY
}

  resource "aws_sqs_queue" "queue" {
	name = "my-sqs-queue"
  }


resource "aws_sqs_queue_policy" "queue_policy" {
 queue_url = aws_sqs_queue.queue.id
 policy = <<POLICY
{
 "Version": "2012-10-17",
 "Id": "example-ID",
 "Statement": [
   {
     "Sid": "Allow-SendMessage",
     "Effect": "Allow",
     "Principal": "sns.amazonaws.com",
     "Action": "sqs:SendMessage",
     "Resource": "${aws_sqs_queue.queue.arn}"
   },
   {
      "Sid": "Allow-User-SetQueueAttributes",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::179500152044:user/new-user"
      },
      "Action": "sqs:SetQueueAttributes",
      "Resource": "${aws_sqs_queue.queue.arn}"
    }
 ]
}
POLICY
}


  resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = aws_s3_bucket.bucket.id

 topic {
   topic_arn     = aws_sns_topic.topic.arn
   events        = ["s3:ObjectCreated:*"]
 }
}

  resource "aws_lambda_function" "lambda" {
	 filename     = "myapp-lambda.zip"
	 function_name = "lambda_function_name"
	 role         = aws_iam_role.iam_for_lambda.arn
	 handler      = "exports.test"

	 source_code_hash = filebase64sha256("./myapp-lambda.zip")

	 runtime = "java8"
}

 resource "aws_s3_bucket_policy" "bucket_policy" {
	bucket = aws_s3_bucket.bucket.id

	policy = <<POLICY
	{
	"Version": "2012-10-17",
	"Statement": [
	{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
 ]
}
POLICY
}

  resource "aws_iam_user" "user" {
   name = "user-name"
 }

 resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


  resource "aws_iam_policy" "s3_policy" {
 name       = "s3-policy"
 description = "A test policy"
 policy     = <<EOF
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

resource "aws_iam_policy" "lambda_policy" {
 name       = "lambda-policy"
 description = "A test policy"
 policy     = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "lambda:*"
     ],
     "Effect": "Allow",
     "Resource": "*"
   }
 ]
}
EOF
}


resource "aws_lambda_permission" "allow_sns_invoke" {
	 statement_id = "AllowExecutionFromSNS"
	 action       = "lambda:InvokeFunction"
	 function_name = aws_lambda_function.lambda.function_name
	 principal    = "sns.amazonaws.com"
	 source_arn   = aws_sns_topic.topic.arn
}

