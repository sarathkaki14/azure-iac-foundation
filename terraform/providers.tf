# -----------------------------------------------------------------------------
# providers.tf - Terraform version, required providers and provider settings.
# The subscription ID is NOT hard-coded. Terraform reads it from the
# ARM_SUBSCRIPTION_ID environment variable (see README).
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      # Lets "terraform destroy" remove the RG even if something extra was added in the portal.
      prevent_deletion_if_contains_resources = false
    }
  }
}
