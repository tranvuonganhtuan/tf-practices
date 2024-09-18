
# data "aws_subnets" "private" {
#   filter {
#     name   = var.vpc_name
#     values = [aws_vpc.main.id]
#   }
#   tags = {
#     Name = "${var.vpc_name}-private-subnet"
#   }
# }

# data "aws_subnets" "public" {
#   filter {
#     name   = var.vpc_name
#     values = [aws_vpc.main.id]
#   }
#   tags = {
#     Name = "${var.vpc_name}-public-subnet"
#   }
# }
