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
  filename   = "${path.module}/../../../ansible/inventory.ini"
  content    = <<-EOF
    [bastion]
    ${local.bastion_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/my-llm-key.pem

    [bastion:vars]
    endpoint=${module.database.db_instance_endpoint}
    db_name=${module.database.db_name}
    db_user=${var.db_username}
    db_password=${var.db_password}
    elb_dns_name=${module.asg_alb.alb_dns_name}

    [asg]
    %{for ip in local.asg_ips~}
    ${ip}
    %{endfor~}
  EOF
  depends_on = [module.bastion, module.database]
}