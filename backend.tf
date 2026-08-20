# Backend S3 per Remote State
# Aggiungere nella root di homepulse-infra/

terraform {
  backend "s3" {
    bucket       = "homepulse-tfstate-prod"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}