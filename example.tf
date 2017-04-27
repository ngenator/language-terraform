# taken from https://github.com/hashicorp/terraform/blob/master/examples/aws-s3-cross-account-access/main.tf

provider "aws" {
	alias = "prod"

	region = "us-east-1"
	access_key = "${var.prod_access_key}"
	secret_key = "${var.prod_secret_key}"
	number = 12kb
	boolean = true
	list = [true, false, 123, "$${var.foo.*} = ${var.foo.*}"]
}

resource "aws_s3_bucket" "prod" {
	provider = "aws.prod"

	bucket = "${concat(var.bucket_name, 4 - 3)}"
	acl = "private"
	policy = <<POLICY_JSON
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowTest",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.test_account_id}:root"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
POLICY_JSON
}

resource "aws_s3_bucket_object" "prod" {
	provider = "aws.prod"

	bucket = "${aws_s3_bucket.prod.id}"
	key = "object-uploaded-via-prod-creds"
	source = "${path.module}/prod.txt"
}

provider "aws" {
	alias = "test"

	region = "us-east-1"
	access_key = "${var.*.test_access_key}"
	secret_key = "${var.test_secret_key}"
}

resource "aws_api_gateway_integration" "ActiveRunnerGetIntegration" {
  rest_api_id             = "${aws_api_gateway_rest_api.CourierAPI.id}"
  resource_id             = "${aws_api_gateway_resource.ActiveRunnerID.id}"
  http_method             = "${aws_api_gateway_method.ActiveRunnerGet.http_method}"
  credentials             = "${aws_iam_role.gateway_invoke_lambda.arn}"
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.apex_function_get_active_runner}:current"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = "${file("request_templates/request_to_event")}"
  }
}

resource "aws_api_gateway_integration_response" "ActiveRunnerGetIntegrationResponse" {
  rest_api_id       = "${aws_api_gateway_rest_api.CourierAPI.id}"
  resource_id       = "${aws_api_gateway_resource.ActiveRunnerID.id}"
  http_method       = "${aws_api_gateway_method.ActiveRunnerGet.http_method}"
  status_code       = "200"
}
