output "bucket_name" {
  description = "S3 bucket holding the site content."
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, used for cache invalidations."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_url" {
  description = "Default CloudFront URL, usable before the DNS cutover."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "custom_domain_url" {
  description = "Custom HTTPS URL served through CloudFront once DNS points at Route 53."
  value       = "https://${var.custom_domain_name}"
}

output "route53_name_servers" {
  description = "Set these as the nameservers at the domain registrar."
  value       = aws_route53_zone.site.name_servers
}

output "deploy_role_arn" {
  description = "IAM role assumed by the GitHub Actions AWS deploy workflow."
  value       = aws_iam_role.deploy.arn
}
