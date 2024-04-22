terraform {
  backend "s3" {
    bucket = "terraform-alura"
    key    = "Prod/terraform.tfstate"
    region = "us-west-2"
  }
}