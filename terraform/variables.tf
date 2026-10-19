# -----------------------------------------------------------------------------
# variables.tf - inputs that change between environments (region, tags, names).
# -----------------------------------------------------------------------------
variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "canadacentral"
}

variable "environment" {
  description = "Environment short name (dev or test)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test"], var.environment)
    error_message = "environment must be dev or test."
  }
}

variable "workload" {
  description = "Short project name used in resource names (lowercase letters and numbers only)."
  type        = string
  default     = "iacfnd"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.workload))
    error_message = "workload must be 3-10 lowercase letters or numbers."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    owner      = "SK"
    project    = "Module4-IaC"
    deployedBy = "Terraform"
  }
}
