locals {
  scope_prefix = var.scope == "CLOUDFRONT" ? "cloudfront" : "regional"
}

resource "aws_wafv2_web_acl" "acl" {
  name  = "${var.app_name}-waf-${local.scope_prefix}"
  scope = var.scope

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList-rule"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${local.scope_prefix}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet-rule"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${local.scope_prefix}-sqli-metrics"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet-rule"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${local.scope_prefix}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet-rule"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${local.scope_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.rate_limit > 0 ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 4
      action {
        block {}
      }
      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.app_name}-${local.scope_prefix}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-waf-${local.scope_prefix}-main-metrics"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, { "name" = "${var.app_name}-waf-${local.scope_prefix}" })
}

# Optional association (for REGIONAL scope resources like API Gateway)
resource "aws_wafv2_web_acl_association" "association" {
  count        = var.resource_arn != "" && var.scope == "REGIONAL" ? 1 : 0
  web_acl_arn  = aws_wafv2_web_acl.acl.arn
  resource_arn = var.resource_arn
}
