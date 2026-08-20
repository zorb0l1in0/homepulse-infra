# Bootstrap — Risorse per Terraform Remote State
# Eseguire UNA VOLTA a mano da WSL, poi non toccare più.
# Stato locale (non gestito dal progetto principale).

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# ---------- S3 Bucket per lo state ----------
resource "aws_s3_bucket" "tfstate" {
  bucket = "homepulse-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "HomePulse"
    Purpose = "Terraform Remote State"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- DynamoDB per state locking ----------
resource "aws_dynamodb_table" "tflock" {
  name         = "homepulse-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "HomePulse"
    Purpose = "Terraform State Locking"
  }
}

# ---------- Data sources ----------
data "aws_caller_identity" "current" {}

# ---------- Outputs ----------
output "state_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "lock_table" {
  value = aws_dynamodb_table.tflock.name
}
