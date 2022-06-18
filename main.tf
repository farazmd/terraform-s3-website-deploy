locals {
    website_domain_name = "${var.dns_name_prefix}.${var.route53_domain}"
}

resource "aws_s3_bucket" "website_s3_bucket" {
    bucket = var.bucket_name
    tags = var.tags
}

resource "aws_s3_bucket_acl" "website_s3_bucket_acl" {
    bucket = var.bucket_name
    acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "wesbite_s3_bucket_config" {
    bucket = var.bucket_name
    index_document {
      suffix = "index.html"
    }
}
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
    bucket                  = var.bucket_name
    ignore_public_acls      = true
    block_public_acls       = true
    restrict_public_buckets = true
    block_public_policy     = true
}

resource "aws_s3_bucket_cors_configuration" "website" {
    bucket = var.bucket_name

    cors_rule {
        allowed_headers = var.website_cors_allowed_headers
        allowed_methods = var.website_cors_allowed_methods
        allowed_origins = concat(["http://${local.website_domain_name}", "https://${local.website_domain_name}"], var.website_cors_additional_allowed_origins)
        expose_headers  = var.website_cors_expose_headers
        max_age_seconds = var.website_cors_max_age_seconds
    }
}