variable "name" {
    type = string
}
variable "delay_seconds" {
        type =   number
        default = 0
}
variable "max_receive_count" {
    type = number
    default = 3                   #الحد الاقصي لعدد مرات السحب 
}
variable "visibility_timeout" {
    type = number
    default = 30                  #الزمن المتاح لمعالجة الرسالة
}
variable "max_size" {
    type = number
    default = 262144              #الحجم الاقصي للرسالة الواحدة
}
variable "retention_seconds" {
    type = number
    default = 86400               # مدة الاحتفاظ بالرسالة 
  
}