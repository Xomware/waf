variable "app_name" {
  description = "Application name, used for naming resources"
  type        = string
}

variable "scope" {
  description = "WAF scope: CLOUDFRONT or REGIONAL"
  type        = string

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "rate_limit" {
  description = "Rate limit (requests per 5 minutes per IP). Set to 0 to disable rate limiting."
  type        = number
  default     = 0
}

variable "resource_arn" {
  description = "ARN of the resource to associate the WAF with (e.g., API Gateway stage ARN). Leave empty to skip association."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "managed_rules" {
  description = "List of AWS managed rule groups to enable. Defaults to IP Reputation + Common Rules."
  type = list(object({
    name        = string
    vendor_name = optional(string, "AWS")
    priority    = number
  }))
  default = [
    { name = "AWSManagedRulesAmazonIpReputationList", priority = 0 },
    { name = "AWSManagedRulesCommonRuleSet", priority = 1 }
  ]
}
