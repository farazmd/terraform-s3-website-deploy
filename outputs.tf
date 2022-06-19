output "cdn_domain" {
  value = aws_cloudfront_distribution.s3_website_cdn.domain_name
}
output "website_domain" {
  value = local.website_domain_name
}