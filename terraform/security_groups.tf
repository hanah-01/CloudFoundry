# ============================================================
# security_groups.tf  –  EC2 & ALB security groups
#
# DevSecOps note:
#   tfsec / Checkov will flag rules that use 0.0.0.0/0.
#   SSH (22) is intentionally locked to a single admin CIDR.
#   In production, SSH should be replaced with SSM Session Manager.
# ============================================================

# -----------------------------------------------------------------
# Web server security group
# -----------------------------------------------------------------
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP/HTTPS inbound; deny everything else"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # tfsec: intentional for web tier
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # tfsec: intentional for web tier
  }

  # Allow SSH only from a defined admin CIDR (defaults to 0.0.0.0/0 for lab)
  ingress {
    description = "SSH from admin network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}
