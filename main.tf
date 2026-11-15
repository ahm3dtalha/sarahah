module "users_table" {
  source     = "./modules/dynamodb-table"
  table_name = "sarahah-users"
  hash_key   = "user_id"

  global_secondary_indexes = [
    { name = "username-index", hash_key = "username" },
    { name = "email-index",    hash_key = "email" },
  ]
}

module "messages_table" {
  source      = "./modules/dynamodb-table"
  table_name  = "sarahah-messages"
  hash_key    = "recipient_id"
  range_key   = "created_at"
  ttl_enabled = false
}

module "messages_queue" {
  source             = "./modules/sqs-with-dlq"
  name               = "sarahah-messages"
  visibility_timeout = 60
}