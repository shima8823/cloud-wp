provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project   = "CloudStudy"
      ManagedBy = "Terraform"
      Owner     = "shima"
    }
  }
}
