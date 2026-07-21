output "arn" {
  value = try(aws_wafv2_web_acl.vss.arn, null)
}
output "id" {
  value = try(aws_wafv2_web_acl.vss.id, null)
}
output "capacity" {
  value = try(aws_wafv2_web_acl.vss.capacity, null)
}