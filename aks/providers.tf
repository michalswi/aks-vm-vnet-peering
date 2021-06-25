provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.65.0"
    #   version = "~>2.0"
    }
  }
  # terraform version
  required_version = ">= 0.13"
}
