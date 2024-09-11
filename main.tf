
#create the vpc
resource "aws_vpc" "quyennv-vpc" {
  cidr_block = var.cidrvpc

  tags = var.tags
}

#create the public subnet
resource "aws_subnet" "public" {

  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.quyennv-vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.quyennv-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-public-subnet"
    },
  var.tags)
}

#create internet gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.quyennv-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-igw"
    },
  var.tags)
}

resource "aws_route" "main-route" {
  route_table_id         = aws_vpc.quyennv-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main-igw.id
}

#assosicate the public subnet to main route table with igw
resource "aws_route_table_association" "public-subnet-rtb" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.quyennv-vpc.main_route_table_id

}

#create the private subnet
resource "aws_subnet" "private" {

  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.quyennv-vpc.cidr_block, 8, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.quyennv-vpc.id
  tags = merge({
    Name = "${var.vpc_name}-private-subnet"
    },
  var.tags)
}

#create the natgate way
resource "aws_eip" "ngweip" {
  count = var.az_count
  tags = merge(
    {
      ext-name = "${var.vpc_name}-ngw-eip-${count.index}"
    },
    var.tags
  )
}
resource "aws_nat_gateway" "ngw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  allocation_id = element(aws_eip.ngweip.*.id, count.index)
  tags = merge(
    { ext-name = "${var.vpc_name}-ngw-eip-${count.index}" }
    ,
    var.tags
  )
}
#create the route table for private subnet
resource "aws_route_table" "private_rtb" {
  count  = var.az_count
  vpc_id = aws_vpc.quyennv-vpc.id

  #define routete for the private subnet
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
  }
  tags = merge(
    {
      ext-name = "${var.vpc_name}-private-rtb-${count.index}"
    },
    var.tags
  )
}

#asosicate the private subnets to private route tables
resource "aws_route_table_association" "private-subnet-rtb" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_rtb.*.id, count.index)
}
