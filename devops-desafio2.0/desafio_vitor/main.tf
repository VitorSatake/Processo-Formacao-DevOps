terraform {  # A seção terraform define a configuração do Terraform para este diretório
  required_providers { # required_providers: Define os provedores necessários para este código. 
    aws = {            # Neste caso, o provedor AWS é necessário.           
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0" # required_version: Define a versão mínima do Terraform necessária para executar este código.
}

provider "aws" { 
  region = var.region # region: É definida como uma variável var.region, o que significa que a região AWS 
}                     # será configurada usando o valor atribuído à variável region.

resource "aws_vpc" "minha_vpc" { # Cria o recuros VPC
  cidr_block = "10.0.0.0/16" # com o bloco de ip dentro do 10.0.0.0/16

  tags = {
    Name = var.name-vpc # com a tag para nomear a vpc.
  }
}

resource "aws_subnet" "public_subnet" { # cria o recurso subnet
  vpc_id            = aws_vpc.minha_vpc.id # associa a subnet a vpc criada
  cidr_block        = "10.0.1.0/24" # define o endereço ip da subnet
  availability_zone = var.region-az-1 # define a zona de disponibilidade onde será criada

  map_public_ip_on_launch = true # Define se os endereços IP públicos serão automaticamente mapeados para instâncias lançadas nesta subnet

  tags = {
    Name = var.name-subpub # com a tag para nomear a subnet.
  }
}


resource "aws_internet_gateway" "minha_igw" { # cria o recurso Internet Gateway, para a vpc ter acesso a internet
  vpc_id = aws_vpc.minha_vpc.id #  Define o id da VPC à qual este gateway estará associado, no caso a VPC que criei

  tags = {
    Name = var.name-igw # com a tag para nomear a internet gateway.
  }
}

resource "aws_route_table" "public_route_table" { # cria o recurso de tabela de rotas
  vpc_id = aws_vpc.minha_vpc.id # Define o id da VPC à qual esta tabela de roteamento estará associada

  route { # Define uma rota na tabela de roteamento.
    cidr_block = "0.0.0.0/0" #  Define o bloco de ips de destino. Aqui, "0.0.0.0/0" representa todos os endereços IP.
    gateway_id = aws_internet_gateway.minha_igw.id # Define o ID do Gateway de Internet associado a esta rota
  }

  tags = {
    Name = var.name-rtb # com a tag para nomear a tabela de rotas.
  }
}

resource "aws_route_table_association" "public_route_association" { # cria uma uma associação de tabela de roteamento.
  subnet_id      = aws_subnet.public_subnet.id # Define a ID da sub-rede à qual esta associação será aplicada.
  route_table_id = aws_route_table.public_route_table.id # Define a ID da tabela de roteamento à qual esta associação será feita.
}

resource "aws_security_group" "minha_sg" { # cria um grupo de segurança.
  name        = var.name-sg # nome do grupo
  description = "security-group"
  vpc_id      = aws_vpc.minha_vpc.id # Define a ID da VPC à qual este grupo de segurança será associado

#ingress: Define as regras de entrada de tráfego para o grupo de segurança.
#São definidas três regras de entrada, permitindo tráfego TCP nas portas 22, 80 e 443 de qualquer endereço IP ("0.0.0.0/0").
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
#egress: Define as regras de saída de tráfego para o grupo de segurança.
#Uma regra de saída permite todo tipo de tráfego para qualquer destino ("0.0.0.0/0").
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"  
  cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = var.name-sg # cria uma tag para o grupo
  }
}

resource "aws_subnet" "private_subnet" { # cria o recurso subnet, por padrao como privada
  vpc_id            = aws_vpc.minha_vpc.id # associa a subnet a vpc criada
  cidr_block        = "10.0.2.0/24" # define o endereço ip da subnet
  availability_zone = var.region-az-1 # define a zona de disponibilidade onde será criada

  tags = {
    Name = var.name-subp-1 # com a tag para nomear a subnet.
  }
}

resource "aws_subnet" "private_subnet_b" { # cria o recurso subnet-b, por padrao como privada
  vpc_id            = aws_vpc.minha_vpc.id # associa a subnet a vpc criada
  cidr_block        = "10.0.3.0/24" # define o endereço ip da subnet
  availability_zone = var.region-az-2 # define a zona de disponibilidade onde será criada

  tags = {
    Name = var.name-subp-2 # com a tag para nomear a subnet.
  }
}


resource "aws_instance" "minha_ec2" { # cria o recurso ec2 
  ami           = var.ami # Define a AMI (Amazon Machine Image) a ser usada para criar a instância.
  instance_type = "t2.micro" # Define o tipo da instância.
  subnet_id     = aws_subnet.public_subnet.id # Define a sub-rede na qual a instância será lançada.
  key_name      = var.key # Define o nome da chave SSH a ser usada para acessar a instância.
  vpc_security_group_ids = [aws_security_group.minha_sg.id] # Define os IDs dos grupos de segurança a serem associados à instância

  tags = {
    Name = var.name-ec2 # com a tag para nomear a ec2.
  }
}

resource "aws_db_subnet_group" "minha_db_subnet_group" { # cria o grupo de sub-redes para o banco de dados RDS.
  name = var.name-db-subnet-group # Define o nome do grupo de sub-redes.
  subnet_ids = [ #  Define as IDs das sub-redes que fazem parte deste grupo, no caso as privadas.
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_b.id
  ]

  tags = {
    Name = var.nome-db-subnet-group # com a tag para nomear o grupo.
  }
}

resource "random_password" "my_password" { # recurso para criar uma senha aleatória
  length           = 12 # tamanho de 12 caracteres
  special          = true # Define se caracteres especiais devem ser incluídos na senha
  override_special = "_%@" #  Permite substituir os caracteres especiais padrão usados na geração da senha. 
  # Neste caso, os caracteres especiais padrão são substituídos por _, % e @.
}

resource "aws_db_instance" "minha_db" { # cria o banco RDS.
    
  engine               = "postgres" # Especifica o tipo de banco de dados.
  engine_version       = "15.5" # a versão do banco
  license_model        = "postgresql-license" # Especifica o modelo de licenciamento do banco de dados.
  instance_class       = "db.t3.micro" # Especifica o tipo da instância do banco de dados
  allocated_storage    = 20 # o tamaho do armazenamento
  identifier           = var.identif # nome da instância de banco de dados.
  username             = var.db_username # nome de usuário para acessar o banco de dados.
  password             = random_password.my_password.result # senha gerada
  db_subnet_group_name = aws_db_subnet_group.minha_db_subnet_group.name # Especifica o nome do grupo de sub-redes do banco de dados.
  skip_final_snapshot    = true # Determina se um snapshot final do banco de dados será criado antes de excluí-lo.

  tags = {
    Name = var.db-nome # com a tag para nomear o banco
  }
}

