#######################################
# WAF Web ACL
#######################################

resource "aws_wafv2_web_acl" "acl" {
  name  = "${var.app_name}-waf-${local.scope_prefix}"
  scope = var.scope

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = "${rule.value.name}-rule"
      priority = rule.value.priority
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.app_name}-${local.scope_prefix}-${lower(rule.value.name)}"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.rate_limit > 0 ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 100
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

#######################################
# Optional Resource Association
#######################################

resource "aws_wafv2_web_acl_association" "association" {
  count        = var.resource_arn != "" && var.scope == "REGIONAL" ? 1 : 0
  web_acl_arn  = aws_wafv2_web_acl.acl.arn
  resource_arn = var.resource_arn
}
