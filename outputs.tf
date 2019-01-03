# Outputs of local environment

output "id" {
  value = "${aws_vpc.main.id}"
}

output "cidr_block" {
  value = "${var.cidr_block}"
}

output "pub_subnets" {
 value = "${compact(aws_subnet.pub.*.id)}"
}

#output "pub__zones" {
# value = "${compact(aws_subnet.pub.*.availability_zone)}"
#}

output "priv_subnets" {
 value = "${compact(aws_subnet.priv.*.id)}"
}

#output "priv_zones" {
# value = [ "${aws_subnet.priv.*.availability_zone}" ]
#}

#output "pub_nat_gateways" {
# value = [ "${aws_eip.nat_gateway.*.public_ip}" ]
#}

output "pub_route_table" {
  value = "${aws_route_table.pub.id}"
}

output "priv_route_tables" {
  value = [ "${aws_route_table.priv.*.id}" ]
}

#output "s3_endpoint" {
#  value = "${aws_vpc_endpoint.s3_endpoint.prefix_list_id}"
#}
