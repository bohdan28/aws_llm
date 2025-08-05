data "aws_instances" "asg" {
  instance_tags = {
    "Environment" = var.environment
    "Name"        = "${var.environment}-asg-instance"
  }

  depends_on = [module.asg]
}

locals {
  bastion_ip = module.bastion.bastion_public_ip
  asg_ips    = data.aws_instances.asg.private_ips # module.asg.asg_private_ips

  depends_on = [module.bastion, module.asg]
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

    [llm]
    llm1
    llm2

    [llm:vars]
    aws_secret_access_key=${var.aws_secret_access_key}
    aws_access_key_id=${var.aws_access_key_id}
    aws_region=${var.aws_region}

  EOF
  depends_on = [module.bastion, module.database]
}

resource "local_file" "ansible_cfg" {
  filename = "${path.module}/../../../ansible/ansible.cfg"
  content  = <<-EOF
    [defaults]
    inventory = inventory.ini
    private_key_file = ~/my-llm-key.pem
    host_key_checking = False
    retry_files_enabled = False
    timeout = 30

    [ssh_connection]
    ssh_args = -F /home/brubl/.ssh/config
  EOF
}