data "aws_instances" "asg" {
  instance_tags = {
    "Environment" = var.environment
    "Name"        = "${var.environment}-asg-instance"
  }
}

locals {
  bastion_ip = module.bastion.bastion_public_ip
  asg_ips    = data.aws_instances.asg.private_ips
}

resource "local_file" "inventory" {
  filename = "${path.module}/../../../ansible/inventory.ini"
  content  = <<-EOF
    [bastion]
    ${local.bastion_ip}

    [asg]
    %{ for ip in local.asg_ips ~}
    ${ip}
    %{ endfor ~}
  EOF
}