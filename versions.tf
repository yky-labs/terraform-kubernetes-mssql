# (c) 2023 yky-labs
# This code is licensed under MIT license (see LICENSE for details)

terraform {
  required_version = ">= 0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }
}
