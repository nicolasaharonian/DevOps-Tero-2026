# Módulo de red: VPC con subredes públicas y privadas en varias zonas de disponibilidad.
#
# - Subredes PÚBLICAS: tienen salida a internet (Internet Gateway). Ahí van el
#   balanceador (ALB) y las tareas de ECS.
# - Subredes PRIVADAS: SIN salida a internet. Ahí van la base de datos y Redis,
#   que solo deben ser accesibles desde dentro de la VPC.
#
# No se usa NAT Gateway para reducir costos en Learner Lab (ver ADR de red).

# Zonas de disponibilidad de la región (us-east-1a, us-east-1b, ...)
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# Puerta de salida de la VPC hacia internet
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# ---------- Subredes públicas ----------
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

# ---------- Tabla de rutas ----------

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.this.id

  # Todo el tráfico hacia fuera de la VPC sale por el Internet Gateway

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }

}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ---------- Subredes privadas ----------

resource "aws_subnet" "private" {

  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name}-private-${local.azs[count.index]}"
    Tier = "private"
  }

}

# Tabla de rutas SIN ruta a internet: solo tráfico dentro de la VPC

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-rt"
  }

}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
 