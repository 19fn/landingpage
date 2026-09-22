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

variable "custom_domain_name" {
  description = "Fully qualified custom hostname, such as example.com or www.example.com."
  type        = string

  validation {
    condition = (
      length(var.custom_domain_name) <= 253 &&
      can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.custom_domain_name))
    )
    error_message = "custom_domain_name must be a lowercase fully qualified domain name."
  }
}

variable "dns_zone_name" {
  description = "Name of the existing Azure DNS zone, such as example.com."
  type        = string

  validation {
    condition = (
      length(var.dns_zone_name) <= 253 &&
      can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.dns_zone_name))
    )
    error_message = "dns_zone_name must be a lowercase fully qualified DNS zone name."
  }
}

variable "dns_zone_resource_group_name" {
  description = "Resource group containing the existing Azure DNS zone."
  type        = string

  validation {
    condition     = length(trimspace(var.dns_zone_resource_group_name)) >= 1 && length(var.dns_zone_resource_group_name) <= 90
    error_message = "dns_zone_resource_group_name must contain between 1 and 90 characters."
  }
}

variable "tags" {
  description = "Tags applied to the resource group and storage account."
  type        = map(string)
  default     = {}
}