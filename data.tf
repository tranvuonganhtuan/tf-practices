#get the total az in current zone
data "aws_availability_zones" "available" {
  state = "available"
}
