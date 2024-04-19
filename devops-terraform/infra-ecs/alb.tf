# --- ALB ---

resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.main.id
  protocol    = "HTTP"
  port        = 5000
  target_type = "instance"

   health_check {
     enabled             = true
     path                = "/ListagemVagas"
     matcher             = "200-499"
     interval            = 10
     timeout             = 5
     healthy_threshold   = 2
     unhealthy_threshold = 3
   }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}

resource "aws_lb_target_group" "appnod" {
  name_prefix = "appnod"
  vpc_id      = aws_vpc.main.id
  protocol    = "HTTP"
  port        = 8000
  target_type = "instance"

   health_check {
     enabled             = true
     path                = "/eventos"
     matcher             = "200-499"
     interval            = 10
     timeout             = 5
     healthy_threshold   = 2
     unhealthy_threshold = 3
   }
}

  # resource "aws_lb_listener" "http-node" {
  #   load_balancer_arn = aws_lb.main.id
  #   port              = 80
  #   protocol          = "HTTP"

  #   default_action {
  #     type             = "forward"
  #     target_group_arn = aws_lb_target_group.appnod.id
  #   }
  # }
