variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-north-1"
}

variable "aws_availability_zone" {
  default = "eu-north-1a"
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}

variable "aws_hosted_zone_id" {
  description = "AWS hosted zone id"
}

variable "aws_host_name" {
  description = "AWS hosted name, e.g: www.example.com"
}

variable "aws_amis" {
  default = {
    eu-central-1 = "ami-5ecdad31"
    eu-north-1   = "ami-03c410dec515e1aa0"
  }
}

variable "aws_key_name" {
  description = "Desired name of AWS key pair"
  default     = "private-factorio"
}

variable "aws_bucket_name" {
  default = "factorio-server"
}

variable "aws_instance_type" {
  default = "t3.micro"
}
