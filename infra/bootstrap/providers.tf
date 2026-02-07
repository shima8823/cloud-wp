provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "cloud-wp/bootstrap"
    }
  }
}
