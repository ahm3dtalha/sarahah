variable "bucket_name" {
    type = string
}
variable "env" {
    type = string
    default = "dev"
}
variable "versioning_enabled" {
    type = bool
    default = true
}