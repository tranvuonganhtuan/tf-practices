output "vpc_id" {
  value = aws_vpc.main.id
}

#export the subnet public

output "public_subnet_id" {
  value = data.aws_subnets.public.ids
}

output "private_subnet_id" {
  value = data.aws_subnets.private.ids
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}
