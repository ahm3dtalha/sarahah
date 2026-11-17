locals {
  attributes = merge(
    tomap({ (var.hash_key) = var.hash_key_type }),
    var.range_key == null ? tomap({}) : tomap({ (var.range_key) = var.range_key_type }),
    { for g in var.global_secondary_indexes : g.hash_key => g.hash_key_type }
  )
}

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode             # نظام الفوترة  
  hash_key     = var.hash_key                 # المفتاح الاساسي
  range_key    = var.range_key                # المفتاح الثانوي ان وجد

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = attribute.key
      type = attribute.value
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      projection_type = "ALL"
    }
  }
  
  dynamic "ttl" {                            # ادارة وقت انتهاء الصلاحية ttl
    for_each = var.ttl_enabled ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }
}