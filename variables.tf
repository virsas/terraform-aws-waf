variable "name" {
  type = string
  description = "The name of the AWS WAFv2 web ACL."
  default = "vss-web-acl"
}

variable "scope" {
  type = string
  description = "The scope of the web ACL. Valid values are `REGIONAL` or `CLOUDFRONT`."
  default = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Valid values for scope are 'REGIONAL' or 'CLOUDFRONT'."
  }
}

variable "default_action" {
  type = string
  description = "The default action to take if no rules match. Valid values are `allow` or `block`."
  default = "allow"
  validation {
    condition     = var.default_action == "allow" || var.default_action == "block"
    error_message = "Valid values for default_action are 'allow' or 'block'."
  }
}

variable "cloudwatch_metrics_enabled" {
  type    = bool
  default = true
  description = "Whether to enable CloudWatch metrics for the web ACL. Default is true."
}

variable "sampled_requests_enabled" {
  type    = bool
  default = false
  description = "Whether to enable request sampling for the web ACL. Default is false."
}

variable "resource_arn" {
  type = string
  description = "The Amazon Resource Name (ARN) of the resource to associate with the web ACL. This can be an Application Load Balancer, an Amazon API Gateway REST API, or an Amazon Cognito user pool."
}

variable "rules" {
  type = map(object({
    name                       = string
    priority                   = number
    type                       = string
    override_action            = optional(string, null)
    action                     = optional(string, null)
    cloudwatch_metrics_enabled = bool
    sampled_requests_enabled   = bool
    # Configurations for specific rule types
    vendor                     = optional(string)
    excluded_rules             = optional(list(string))
    # ... add configurations for other types as needed ...
  }))
  description = <<EOF
    A map of rules to be included in the web ACL.

    Each rule must have the following attributes:

    * `name`: The name of the rule.
    * `description`: A detailed description of the rule's purpose and functionality.
    * `priority`: The priority of the rule. Rules with lower priority numbers are evaluated first.
    * `type`: The type of the rule. Currently supported: `managed_rule_group`.
    * `override_action`: (Optional, only for `managed_rule_group` type) The action to override the default action of the managed rule group. Valid values are: `none`, `count`, `allow`, `block`. None will inherit the action from the managed rule group.
    * `action`: (Optional, for all types except `managed_rule_group`) The action to take when the rule matches. Valid values are: `allow`, `block`, `count`.
    * `cloudwatch_metrics_enabled`: Whether to enable CloudWatch metrics for the rule.
    * `sampled_requests_enabled`: Whether to enable request sampling for the rule.

    Example for AWSManagedRulesCommonRuleSet with GenericRFI_BODY exclusion:

    rules = {
      common_rule_set = {
        name                       = "common_rule_set"
        description                = "AWS Managed Rules Common Rule Set with GenericRFI_BODY exclusion"
        priority                   = 1
        type                       = "managed_rule_group"
        override_action            = "none"
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        vendor                     = "AWS"
        excluded_rules             = ["GenericRFI_BODY"]
      }
    }
  EOF
}