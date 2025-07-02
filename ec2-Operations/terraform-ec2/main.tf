provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Project = "GoormPlay"
    Environment = "Development"
  }
  
  services = [
    "eureka",
    "UI-service",
    "userAction-test-service",
    "subscribe-service",
    "auth-service",
    "indexing-service",
    "review-service",
    "content-service",
    "member-service",
    "ad-service",
    "apigateway-service"
  ]
}

# EC2 instances for each service
resource "aws_instance" "service_instances" {
  for_each = toset(local.services)
  
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  
  user_data = file("${path.module}/../userdata-scripts/${each.key == "eureka" ? "eureka-userdata.sh" : "${each.key}-userdata-updated.sh"}")
  
  tags = merge(
    local.common_tags,
    {
      Name = "${each.key}-instance"
    }
  )
}
