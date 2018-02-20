variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-central-1"
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}

variable "aws_amis" {
  default = {
    eu-central-1 = "ami-5ecdad31"
  }
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default     = "private-factorio"
}
