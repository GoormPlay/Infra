variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-090190993f1fe3eac"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instances"
  type        = string
  default     = "subnet-00c246ce288c3cbf8"
}

variable "security_group_id" {
  description = "Security Group ID for EC2 instances"
  type        = string
  default     = "sg-08dfb9c0d61c0062a"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "test"
}

variable "iam_instance_profile" {
  description = "IAM instance profile for EC2 instances"
  type        = string
  default     = "ec2-ami-msa"
}
