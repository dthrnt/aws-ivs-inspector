# create cloudwatch log group for lambda
resource "aws_amplify_app" "amplify_app" {
  name                     = "aws-${var.project_name}"
  repository               = var.repository
  access_token             = var.token
  enable_branch_auto_build = true


  # The default build_spec added by the Amplify Console for React.
  build_spec = <<-EOT
    version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            - npm i
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist/spa
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  environment_variables = {
    VITE_ACCOUNT_ID : var.account_id,
  }

  enable_auto_branch_creation = true

  # The default patterns added by the Amplify Console.
  auto_branch_creation_patterns = [
    "*",
    "*/**",
  ]

  auto_branch_creation_config {
    enable_auto_build       = true
    enable_performance_mode = true
  }
}

resource "aws_amplify_branch" "amplify_branch" {
  app_id            = aws_amplify_app.amplify_app.id
  branch_name       = var.branch_name
  framework         = "Vue"
  stage             = "PRODUCTION"
  enable_auto_build = true
}

resource "aws_amplify_backend_environment" "example" {
  app_id               = aws_amplify_app.amplify_app.id
  environment_name     = "backend"
  deployment_artifacts = "initial-deployment"
  stack_name           = "${var.project_name}-web-stack"
}

resource "aws_amplify_domain_association" "domain_association" {
  app_id                = aws_amplify_app.amplify_app.id
  domain_name           = var.domain_name
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.amplify_branch.branch_name
    prefix      = "ivs"
  }

}

resource "aws_amplify_webhook" "master" {
  app_id      = aws_amplify_app.amplify_app.id
  branch_name = aws_amplify_branch.amplify_branch.branch_name
  description = "triggerivs"
}