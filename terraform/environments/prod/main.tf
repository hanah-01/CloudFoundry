module "web_stack" {
  source = "../../modules/web_stack"

  name_prefix         = var.name_prefix
  environment         = var.environment
  aws_region          = var.aws_region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
  instance_type       = var.instance_type
  ami_id              = var.ami_id
  key_name            = var.key_name

  enable_compute       = var.enable_compute
  enable_self_healing  = var.enable_self_healing
  enable_load_balancer = var.enable_load_balancer

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  alb_ingress_cidr   = var.alb_ingress_cidr
  app_ingress_cidr   = var.app_ingress_cidr
  ssh_ingress_cidr   = var.ssh_ingress_cidr
  health_check_path  = var.health_check_path
  index_page_content = var.index_page_content

  s3_bucket_name    = var.s3_bucket_name
  lambda_runtime    = var.lambda_runtime
  localstack_mode   = var.localstack_mode
  enable_monitoring = var.enable_monitoring

  tags = var.tags
}