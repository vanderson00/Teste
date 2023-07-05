terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    fortiflexvm = {
      source = "fortinetdev/fortiflexvm"
      version = "1.0.0"
  }
}
}