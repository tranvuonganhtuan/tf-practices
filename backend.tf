terraform {
  backend "s3" {
    bucket = "vtiquyennvtfstate"
    key    = "tfstate"
    region = "ap-southeast-1"
  }
}
