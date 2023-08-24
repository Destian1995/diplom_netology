variable "YC_CLOUD_ID" {
  default = "b1gfodjsfjm1ue7u0ld7"
}

variable "YC_FOLDER_ID" {
  default = "b1ggthdvv3nparichh2u"
}

variable count_format { 
  default = "%01d" 
} #server number format (-1, -2, etc.)

variable count_offset { 
  default = 0 
} #start numbering from X+1 (e.g. name-1 if '0', name-3 if '2', etc.)

# variable "s3_access_key" {
#   default = ""
# }

# variable "s3_secret_key" {
#   default = ""
# }
