# waf

Reusable Terraform module that creates an AWS WAFv2 Web ACL with AWS managed rule groups and optional rate limiting. Works with both CloudFront (CLOUDFRONT scope) and regional resources like API Gateway (REGIONAL scope).

## What it creates

- WAFv2 Web ACL with 4 AWS managed rule groups
- Optional rate limiting rule (per-IP)
- Optional resource association (for REGIONAL scope)
- CloudWatch metrics for all rules

## Managed Rules Included

| Priority | Rule Group | Description |
|----------|-----------|-------------|
| 0 | `AWSManagedRulesAmazonIpReputationList` | Blocks requests from IPs with poor reputation |
| 1 | `AWSManagedRulesSQLiRuleSet` | SQL injection protection |
| 2 | `AWSManagedRulesKnownBadInputsRuleSet` | Blocks known bad input patterns |
| 3 | `AWSManagedRulesCommonRuleSet` | OWASP top 10 and common threat protection |
| 4 | `RateLimitRule` (optional) | Per-IP rate limiting |

## Usage

### CloudFront WAF

```hcl
module "waf_cloudfront" {
  source = "git::https://github.com/domgiordano/waf.git?ref=v1.0.0"

  app_name = "myapp-cloudfront"
  scope    = "CLOUDFRONT"
  tags     = { source = "terraform", app_name = "myapp" }
}

# Pass the ARN to your CloudFront distribution or web-hosting module
module "web" {
  source      = "git::https://github.com/domgiordano/web-hosting.git?ref=v1.0.0"
  waf_acl_arn = module.waf_cloudfront.web_acl_arn
  # ...
}
```

### API Gateway WAF (with rate limiting and auto-association)

```hcl
module "waf_api_gateway" {
  source = "git::https://github.com/domgiordano/waf.git?ref=v1.0.0"

  app_name     = "myapp-api-gateway"
  scope        = "REGIONAL"
  rate_limit   = 2000  # requests per 5 minutes per IP
  resource_arn = module.api.stage_arn
  tags         = { source = "terraform", app_name = "myapp" }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `app_name` | Application name for resource naming | `string` | — | yes |
| `scope` | WAF scope: `CLOUDFRONT` or `REGIONAL` | `string` | — | yes |
| `rate_limit` | Rate limit (requests per 5 min per IP). Set to `0` to disable. | `number` | `0` | no |
| `resource_arn` | ARN of the resource to associate (e.g., API Gateway stage). Empty to skip. | `string` | `""` | no |
| `tags` | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_arn` | The WAF Web ACL ARN (for CloudFront `web_acl_id` or manual associations) |
| `web_acl_id` | The WAF Web ACL ID |

## Notes

- **CLOUDFRONT scope** WAFs must be created in `us-east-1`. Ensure your provider is configured accordingly.
- **REGIONAL scope** WAFs are created in the same region as your provider and can auto-associate with a resource via `resource_arn`.
- **Rate limiting** is only added when `rate_limit > 0`. Common values: 2000 (moderate), 1000 (strict), 5000 (lenient).
- **Association** is only created when both `resource_arn` is set and `scope` is `REGIONAL`. For CLOUDFRONT scope, pass the `web_acl_arn` output to your CloudFront distribution's `web_acl_id` argument instead.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| AWS Provider | >= 4.0 |
