resource "aws_instance" "web_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_server.id]
  associate_publics_ip_address = true

  key_name = var.ec2_key_name != "" ? var.ec2_key_name : null

  # User data bootstraps Nginx so the instance is ready immediately
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    amazon-linux-extras install nginx1 -y
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Deployed by Terraform on LocalStack | ${var.project_name}</h1>" \
      > /usr/share/nginx/html/index.html
  EOF
  )

  # Store instance state in a named volume (LocalStack persists this)
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true   # DevSecOps: encrypt root volume
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-server"
    Role = "web"
  })
}
