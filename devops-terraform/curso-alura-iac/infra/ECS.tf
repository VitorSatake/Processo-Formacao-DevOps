module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.ambiente

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.cargo.arn
  container_definitions    = jsonencode(
[
  {
    "name" = "variavel"
    "image" = "caminho-da-imagem"
    "cpu" = 1024
    "memory" = 2048
    "essential" = true
    "portMappings" = [
      {
        "containerPort" = 8000
        "hostPort" = 8000
      }
    ]
  }
]
)
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3

  load_balancer {
    target_group_arn = aws_lb_target_group.alvo.arn
    container_name   = "variavel"
    container_port   = 8000
  }

  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.privado.id]
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight = 1
  }
}