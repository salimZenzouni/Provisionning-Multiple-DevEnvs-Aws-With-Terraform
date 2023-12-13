output "instance_public_ips" {
  value = [for instance in aws_instance.v2_dev_ubuntu : instance.public_ip]
  description = "List of public IP addresses of the EC2 instances"
}
