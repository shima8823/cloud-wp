provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "cloud-wp/app"
    }
  }
}

# c211 probe marker: non-destructive comment to trigger terraform plan
