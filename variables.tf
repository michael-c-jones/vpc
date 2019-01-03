
# header level defaults

# dev, qa, prod
variable "env" {}

# us-east-1, etc.
variable "region" {}

# vpc variables

variable "cidr_block" {}

variable "zones" { 
  type = "list"
}

variable "pub_cidrs" { 
  type = "list"
}

variable "priv_cidrs" { 
  type = "list"
}
