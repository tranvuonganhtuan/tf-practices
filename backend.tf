terraform {
  cloud {

    organization = "vti-practices-tf"

    workspaces {
      name = "prod"
    }
  }
}


