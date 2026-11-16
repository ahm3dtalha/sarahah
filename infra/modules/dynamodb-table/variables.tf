variable "table_name" {
    type = string
    description = "shoud be entred"
}
variable "user_id" {
    type = string
    default = "user_id"
}
variable "ttl_attribute" {
    type = string
    default = "expires_at"
}
variable "ttl_enabled" {
    type = bool
    default = true
}
variable "hash_key" {
    type = string
    default = "id"
    description = "shoud be entred"
}
variable "hash_key_type" {
    type = string
    default = "S"

validation {
    condition = contains(["S","N","B"],var.hash_key_type)
    error_message = "hash_key_type nust be S,N, or B"
    }
}
variable "billing_mode" {
    type = string
    default = "PAY_PER_REQUEST"

validation {
    condition = contains(["PAY_PER_REQUEST","PROVISIONED"],var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED"
    }
}
variable "range_key" {
    type    = string
    default = null
}

variable "range_key_type" {
    type    = string
    default = "S"
}

variable "global_secondary_indexes" {
    type = list(object({
    name              = string
    hash_key          = string
    hash_key_type     = optional(string, "S")
    range_key         = optional(string)
    range_key_type    = optional(string, "S")
    projection_type   = optional(string, "ALL")
    non_key_attributes = optional(list(string), [])
    }))
    default = []
}