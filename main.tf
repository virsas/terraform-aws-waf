resource "aws_wafv2_web_acl" "vss" {
  name     = var.name
  scope    = var.scope

  dynamic "default_action" {
    for_each = var.default_action == "allow" ? [1] : []
    content {
      allow {}
    }
  }

  dynamic "default_action" {
    for_each = var.default_action == "block" ? [1] : []
    content {
      block {}
    }
  }


  visibility_config {
    metric_name                = var.name
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "override_action" {
        for_each = rule.value.type == "managed_rule_group" && rule.value.override_action == "none" ? [1] : []
        content {
          none {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.type == "managed_rule_group" && rule.value.override_action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.type == "managed_rule_group" && rule.value.override_action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.type == "managed_rule_group" && rule.value.override_action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = rule.value.type != "managed_rule_group" && rule.value.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.type != "managed_rule_group" && rule.value.action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = rule.value.type != "managed_rule_group" && rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        # Flexible statement based on rule type
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.type == "managed_rule_group" ? [rule.value] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor

            dynamic "rule_action_override" {
              for_each = managed_rule_group_statement.value.excluded_rules
              content {
                dynamic "action_to_use" {
                  for_each = rule.value.override_action == "count" || rule.value.override_action == "allow" ? [1] : []
                  content {
                    block {}
                  }
                }
                dynamic "action_to_use" {
                  for_each = rule.value.override_action == "block" || rule.value.override_action == "none" ? [1] : []
                  content {
                    allow {}
                  }
                }
                name = rule_action_override.value
              }
            }
          }
        }

        # If needed we can add more statement types here in the future
      }

      visibility_config {
        metric_name                = rule.value.name
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }
}

resource "aws_wafv2_web_acl_association" "vss" {
  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.vss.arn
}