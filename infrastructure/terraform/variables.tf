variable "subscription_id" {
  description = "Azure subscription ID where the landing-page resources will be created."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid UUID."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group Terraform will create."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must contain between 1 and 90 characters."
  }
}

variable "resource_group_location" {
  description = "Azure location where Terraform will create the resource group, for example eastus2."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_location)) > 0
    error_message = "resource_group_location must not be empty."
  }
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name using 3-24 lowercase letters and numbers."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must contain 3-24 lowercase letters and numbers only."
  }
}

variable "tags" {
  description = "Tags applied to the resource group and storage account."
  type        = map(string)
  default     = {}
}