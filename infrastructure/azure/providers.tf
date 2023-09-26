provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.29.0"
    }
  }
}
