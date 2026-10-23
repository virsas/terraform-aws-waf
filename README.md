# Terraform AWS WAF Module

A Terraform module for managing an [AWS WAFv2](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html) web ACL and its association with a protected resource. The module builds the web ACL from a map of rules, currently supporting AWS and third-party managed rule groups with per-rule overrides, and attaches the resulting ACL to an Application Load Balancer, API Gateway REST API, AppSync GraphQL API or Cognito user pool.

## Features

- **Web ACL Management**: Creates a WAFv2 web ACL with a configurable name and a `REGIONAL` or `CLOUDFRONT` scope.
- **Default Action**: Allows or blocks every request that no rule matches.
- **Managed Rule Groups**: Adds AWS or third-party managed rule groups from a single `rules` map, each with its own priority and vendor.
- **Rule Overrides**: Supports `none`, `count`, `allow` and `block` override actions for managed rule groups, plus per-rule action overrides for individual rules inside a group.
- **Visibility Configuration**: Toggles CloudWatch metrics and request sampling both for the web ACL and for every rule individually.
- **Resource Association**: Associates the web ACL with the ARN of the resource that should be protected.

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

---

## Usage Examples

> [!NOTE]  
> Every entry in `rules` must set `excluded_rules`. The module iterates over that list when building the `rule_action_override` blocks, so leaving it unset results in an error. Pass an empty list when no rule inside the managed rule group should be overridden.

### Basic Example

Protect an Application Load Balancer with the AWS common rule set, keeping the managed rule group's own actions:

```hcl
module "waf" {
  source = "git::https://github.com/virsas/terraform-aws-waf.git?ref=v1.1"

  name         = "vss-application-acl"
  scope        = "REGIONAL"
  resource_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/vss-application/1234567890abcdef"

  rules = {
    common_rule_set = {
      name                       = "AWSManagedRulesCommonRuleSet"
      priority                   = 1
      type                       = "managed_rule_group"
      override_action            = "none"
      vendor                     = "AWS"
      excluded_rules             = []
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }
}
```

### Advanced Example (Multiple Rule Groups and Exclusions)

Block by default, stack several AWS managed rule groups and exclude individual rules from the common rule set:

```hcl
module "waf_strict" {
  source = "git::https://github.com/virsas/terraform-aws-waf.git?ref=v1.1"

  name           = "vss-application-acl-strict"
  scope          = "REGIONAL"
  default_action = "block"

  cloudwatch_metrics_enabled = true
  sampled_requests_enabled   = true

  resource_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/vss-application/1234567890abcdef"

  rules = {
    common_rule_set = {
      name                       = "AWSManagedRulesCommonRuleSet"
      priority                   = 1
      type                       = "managed_rule_group"
      override_action            = "none"
      vendor                     = "AWS"
      excluded_rules             = ["GenericRFI_BODY", "SizeRestrictions_BODY"]
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }

    known_bad_inputs = {
      name                       = "AWSManagedRulesKnownBadInputsRuleSet"
      priority                   = 2
      type                       = "managed_rule_group"
      override_action            = "none"
      vendor                     = "AWS"
      excluded_rules             = []
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }

    sql_injection = {
      name                       = "AWSManagedRulesSQLiRuleSet"
      priority                   = 3
      type                       = "managed_rule_group"
      override_action            = "none"
      vendor                     = "AWS"
      excluded_rules             = []
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }
}
```

### Count Mode Example (Monitoring Before Enforcement)

Evaluate a new managed rule group without blocking traffic by setting the override action to `count`:

```hcl
module "waf_monitoring" {
  source = "git::https://github.com/virsas/terraform-aws-waf.git?ref=v1.1"

  name           = "vss-application-acl-monitoring"
  scope          = "REGIONAL"
  default_action = "allow"

  resource_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/vss-application/1234567890abcdef"

  rules = {
    bot_control = {
      name                       = "AWSManagedRulesBotControlRuleSet"
      priority                   = 1
      type                       = "managed_rule_group"
      override_action            = "count"
      vendor                     = "AWS"
      excluded_rules             = []
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }
}
```

---

## Resources

| Name | Type |
|------|------|
| [aws_wafv2_web_acl.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the AWS WAFv2 web ACL, also used as the CloudWatch metric name of the ACL. | `string` | `"vss-web-acl"` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | The scope of the web ACL. Allowed values: `REGIONAL` or `CLOUDFRONT`. | `string` | `"REGIONAL"` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | The default action to take when no rule matches. Allowed values: `allow` or `block`. | `string` | `"allow"` | no |
| <a name="input_cloudwatch_metrics_enabled"></a> [cloudwatch\_metrics\_enabled](#input\_cloudwatch\_metrics\_enabled) | Whether to enable CloudWatch metrics for the web ACL. | `bool` | `true` | no |
| <a name="input_sampled_requests_enabled"></a> [sampled\_requests\_enabled](#input\_sampled\_requests\_enabled) | Whether to enable request sampling for the web ACL. | `bool` | `false` | no |
| <a name="input_resource_arn"></a> [resource\_arn](#input\_resource\_arn) | ARN of the resource to associate with the web ACL, such as an Application Load Balancer, an Amazon API Gateway REST API or an Amazon Cognito user pool. | `string` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of rules to include in the web ACL. `name` is the rule name (the managed rule group name for `managed_rule_group` rules), `priority` orders evaluation from lowest to highest, `type` selects the statement kind and currently supports only `managed_rule_group`, `override_action` overrides the managed rule group action and accepts `none`, `count`, `allow` or `block`, `action` applies to all other types and accepts `allow`, `block` or `count`, `vendor` is the managed rule group vendor (e.g. `AWS`), `excluded_rules` lists rules inside the group that receive an inverted action, and the two visibility flags control CloudWatch metrics and request sampling per rule. | <pre>map(object({<br>  name                       = string<br>  priority                   = number<br>  type                       = string<br>  override_action            = optional(string, null)<br>  action                     = optional(string, null)<br>  cloudwatch_metrics_enabled = bool<br>  sampled_requests_enabled   = bool<br>  vendor                     = optional(string)<br>  excluded_rules             = optional(list(string))<br>}))</pre> | n/a | yes |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the WAFv2 web ACL. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the WAFv2 web ACL. |
| <a name="output_capacity"></a> [capacity](#output\_capacity) | The web ACL capacity units (WCU) currently consumed by the rules of the web ACL. |

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
