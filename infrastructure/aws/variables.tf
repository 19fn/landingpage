variable "aws_profile" {
  description = "AWS CLI profile used by Terraform."
  type        = string
  default     = "personal"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the site content."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 lowercase letters, numbers, dots, or hyphens."
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
  description = "DNS zone name, such as example.com. Terraform creates a Route 53 hosted zone with this name."
  type        = string

  validation {
    condition = (
      length(var.dns_zone_name) <= 253 &&
      can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.dns_zone_name))
    )
    error_message = "dns_zone_name must be a lowercase fully qualified DNS zone name."
  }
}

variable "redirect_apex_to_custom_domain" {
  description = "When custom_domain_name is a subdomain (such as www.example.com), also serve the zone apex through CloudFront and permanently redirect it there."
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "github_oidc_subject_prefix" {
  description = "OIDC subject prefix of the GitHub repository allowed to assume the deploy role. The repository uses immutable subjects, which include the owner and repository IDs; read it with 'gh api repos/OWNER/REPO/actions/oidc/customization/sub'."
  type        = string
  default     = "repo:19fn@69449278/landingpage@1382181071"
}

variable "github_environment" {
  description = "GitHub Environment allowed to assume the deploy role."
  type        = string
  default     = "production"
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider. Set to false if the account already has one."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all AWS resources."
  type        = map(string)
  default     = {}
}
