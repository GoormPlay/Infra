# Output the public IPs of all instances
output "instance_public_ips" {
  value = {
    for service, instance in aws_instance.service_instances :
    service => instance.public_ip
  }
}

# Output the instance IDs of all instances
output "instance_ids" {
  value = {
    for service, instance in aws_instance.service_instances :
    service => instance.id
  }
}

# Output the private IPs of all instances
output "instance_private_ips" {
  value = {
    for service, instance in aws_instance.service_instances :
    service => instance.private_ip
  }
}
