# Define provider
provider "aws" {
  region = "us-east-1"
}

# Create Data Base
resource "aws_dynamodb_table" "example_table" {
  name         = "example-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

# Create AppSync API

resource "aws_appsync_graphql_api" "example" {
  name                = "example-api"
  authentication_type = "API_KEY"

  schema = file("schema.graphql")

}

# Create Resolvers API
resource "aws_appsync_resolver" "example_resolver" {
  api_id            = aws_appsync_graphql_api.example.id
  type              = "Query"
  field             = "getExample"
  request_template  = file("${path.module}/resolvers/example_resolver.req.vtl")
  response_template = file("${path.module}/resolvers/example_resolver.res.vtl")

  data_source = aws_appsync_datasource.exampleDatasource.name

}

resource "aws_appsync_resolver" "another_resolver" {
  api_id            = aws_appsync_graphql_api.example.id
  type              = "Query"
  field             = "getExample2"
  request_template  = file("${path.module}/resolvers/another_resolver.req.vtl")
  response_template = file("${path.module}/resolvers/another_resolver.res.vtl")

  data_source = aws_appsync_datasource.exampleDatasource.name
}

# Resource Rol

resource "aws_iam_role" "example_datasource_role" {
  name = "ExampleDataSourceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create Data Source

resource "aws_appsync_datasource" "exampleDatasource" {
  api_id           = aws_appsync_graphql_api.example.id
  name             = "exampleDatasource"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = aws_iam_role.example_datasource_role.arn
  dynamodb_config {
    table_name = aws_dynamodb_table.example_table.name
  }
}
