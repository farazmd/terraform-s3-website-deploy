variable "bucket_name" {}
variable "route53_domain" {}
variable "dns_name_prefix" {}
variable "tags" {}
variable "website_cors_allowed_headers" {
  description = "Default Allowed Headers"
  default     = ["Authorization", "Content-Length"]
}
variable "website_cors_allowed_methods" {
  description = "Default Allowed Methods"
  default     = ["HEAD", "GET", "POST"]
}
variable "website_cors_expose_headers" {
  default = []
}
variable "website_cors_max_age_seconds" {
  default = 3600
}