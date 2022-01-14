terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

resource "aws_apigatewayv2_vpc_link" "terra_trial_vpclink" {
  name               = "terra_trial_vpclink"
  security_group_ids = ["sg-09a3195270df41"]
  subnet_ids         = ["subnet-0cdb4873efdf12", "subnet-070ee8978b07dd"]

  tags = {
    Usage = "example"
  }
}

resource "aws_apigatewayv2_api" "terra_trial_http_api" {
  name          = "terra_trial_example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "terra_trial_stage" {
  api_id = aws_apigatewayv2_api.terra_trial_http_api.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "terra-trial-authorizer" {
  api_id           = aws_apigatewayv2_api.terra_trial_http_api.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = "arn:aws:lambda:eu-west-1:49395033:function:trial-apigateway-authorizer"
  enable_simple_responses = "true"
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds = 0
  #identity_sources = ["$request.header.Authorization"]
  name             = "terra-trial-authorizer"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.terra_trial_http_api.id
  #credentials_arn  = aws_iam_role.example.arn
  description      = "Example with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = "arn:aws:elasticloadbalancing:eu-west-1:49325033:listener/app/HK-onb-ALB/26e82f7eb2/a19aacb3074d5"

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.terra_trial_vpclink.id
}

resource "aws_apigatewayv2_route" "terra-trial-route" {
  api_id    = aws_apigatewayv2_api.terra_trial_http_api.id
  route_key = "ANY /"
  target = "integrations/${aws_apigatewayv2_integration.example.id}"
}



