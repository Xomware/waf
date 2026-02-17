locals {
  scope_prefix = var.scope == "CLOUDFRONT" ? "cloudfront" : "regional"
}
