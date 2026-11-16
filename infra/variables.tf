variable "bucket_name" {
    type = string
}
variable "file_name" {
    type = string 
}
variable "text_to_file" {
    type = string
}
variable "s3_list" {
    type = list(string)
}
variable "dl_queue" {
    type = string
    default = "my-default-dl-queue"
}
variable "main_queue" {
  
}