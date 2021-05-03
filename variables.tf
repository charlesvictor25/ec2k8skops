variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {
        default = "eu-west-2"
}
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.3.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default = "10.3.1.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "eu-west-2a"
}
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/id_rsa.pub"
}
variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default = "ami-08b993f76f42c3e2f"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default = "t2.micro"
}
variable "environment_tag" {
  description = "Environment tag"
  default = "Demo-k8s"
}
