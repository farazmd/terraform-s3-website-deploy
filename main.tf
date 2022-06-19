locals {
  website_domain_name             = var.dns_name_prefix != "" ? "${var.dns_name_prefix}.${var.route53_domain}" : "${var.route53_domain}"
  website_cors_additional_origins = var.dns_name_prefix != "" ? [] : [["http://www.${local.website_domain_name}", "https://www.${local.website_domain_name}"]]
}

###### Data ######

data "aws_route53_zone" "r53_hosted_zone" {
  name = var.route53_domain
}

data "aws_acm_certificate" "acm_cert" {
  domain = var.route53_domain
}

###### S3 Bucket With Static Hosting ######
resource "aws_s3_bucket" "website_s3_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "website_s3_bucket_acl" {
  bucket = var.bucket_name
  acl    = "private"
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
    allowed_origins = concat(["http://${local.website_domain_name}", "https://${local.website_domain_name}"], local.website_cors_additional_origins)
    expose_headers  = var.website_cors_expose_headers
    max_age_seconds = var.website_cors_max_age_seconds
  }
}

###### CDN ######

resource "aws_cloudfront_origin_access_identity" "s3_origin_id" {
  comment = "S3 website origin access identity"
}

resource "aws_cloudfront_distribution" "s3_website_cdn" {
  origin {
    origin_id   = "${var.bucket_name}-origin"
    domain_name = aws_s3_bucket.website_s3_bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_origin_id.cloudfront_access_identity_path
    }
  }
  enabled             = true
  aliases             = var.dns_name_prefix != "" ? [local.website_domain_name] : [local.website_domain_name, "www.${local.website_domain_name}"]
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.bucket_name}-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_100"
  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.acm_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLS1.2"
  }
  wait_for_deployment = true
}


###### Route53 ######
resource "aws_route53_record" "website_record" {
  name    = local.website_domain_name
  zone_id = data.aws_route53_zone.r53_hosted_zone.zone_id
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.s3_website_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.s3_website_cdn.hosted_zone_id
  }
}

resource "aws_route53_record" "www_website_record" {
  count   = var.dns_name_prefix != "" ? 0 : 1
  name    = "www.${local.website_domain_name}"
  zone_id = data.aws_route53_zone.r53_hosted_zone.zone_id
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.s3_website_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.s3_website_cdn.hosted_zone_id
  }
}