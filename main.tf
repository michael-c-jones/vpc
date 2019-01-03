
# establish basic vpc infrastructure


locals {
  shortregion = "${replace(var.region, "-", "")}"
  full_id     = "${var.env}-${local.shortregion}"
}


resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name           = "${local.full_id}"
    env            = "${var.env}"
    provisioned_by = "terraform"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name           = "${local.full_id}"
    vpc            = "${aws_vpc.main.id}"
    env            = "${var.env}"
    provisioned_by = "terraform"
  }
}


# subnets
resource "aws_subnet" "pub" {
  count  = "${length(var.pub_cidrs)}"

  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.pub_cidrs, count.index)}"
  availability_zone       = "${element(var.zones, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name           = "public-${substr(element(var.zones, count.index), -1, 1)}-${local.full_id}"
    env            = "${var.env}"
    provisioned_by = "terraform"
  }
}


resource "aws_subnet" "priv" {
  count = "${length(var.priv_cidrs)}"

  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.priv_cidrs, count.index)}"
  availability_zone       = "${element(var.zones, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name           = "private-${substr(element(var.zones, count.index), -1, 1)}-${local.full_id}"
    environment    = "${var.env}"
    provisioned_by = "terraform"
  }

}


# Create a NAT Gateway for each Availability Zone and puts it in the first public subnet
# public subnet on each zone.
resource "aws_eip" "nat_gateway" {
  count = "${length(var.zones)}"
  vpc   = true
}

resource "aws_nat_gateway" "gw" {
  count = "${length(var.zones)}"

  allocation_id = "${element(aws_eip.nat_gateway.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.pub.*.id, count.index)}"

  depends_on    = [ "aws_internet_gateway.main" ]
}


# vpc endpoint for s3
# I want to believe that this works, I really do
resource "aws_vpc_endpoint" "s3_endpoint" {

  vpc_id = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [
    "${aws_route_table.pub.id}",
    "${aws_route_table.priv.*.id}"
  ]
  policy = <<EOF
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ],
    "Version": "2008-10-17"
}
EOF
}


# public route table and a default route out through the internet gateway
resource "aws_route_table" "pub" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name           = "public-${local.full_id}"
    environment    = "${var.env}"
    provisioned_by = "terraform"
  }
}

resource "aws_route" "pub_internet_gateway" {
  route_table_id = "${aws_route_table.pub.id}"
  gateway_id     = "${aws_internet_gateway.main.id}"

  destination_cidr_block = "0.0.0.0/0"
}

# associate the route table with our public subnets
resource "aws_route_table_association" "pub" {
  count = "${length(var.pub_cidrs)}"

  route_table_id = "${aws_route_table.pub.id}"
  subnet_id = "${element(aws_subnet.pub.*.id, count.index)}"
}

# rout table and default route for each private subnet
resource "aws_route_table" "priv" {
  count = "${length(var.zones)}"

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "private-${substr(element(var.zones, count.index), -1, 1)}-${local.full_id}"
    environment    = "${var.env}"
    provisioned_by = "terraform"
  }
}

resource "aws_route" "priv_nat_gw" {
  count = "${length(var.zones)}"

  nat_gateway_id = "${element(aws_nat_gateway.gw.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.priv.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
}


resource "aws_route_table_association" "priv" {
  count = "${length(var.priv_cidrs)}"

  route_table_id = "${element(aws_route_table.priv.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.priv.*.id, count.index)}"
}
