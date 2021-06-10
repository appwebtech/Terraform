output "vpc-id" {
  value = aws_vpc.kaseo-restaurant-ltd.id
}
output "db-id-AZ-1" {
  value = aws_subnet.kaseo-private-db-1.id
}
output "db-id-AZ-2" {
  value = aws_subnet.kaseo-private-db-2.id
}
output "aws-ami-id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}
