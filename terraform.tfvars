vpc_cidr_block = "10.0.0.0/16"
kaseo-vpc      = "kaseo manchester area"
my_ip          = "192.168.1.98/32"
instance_type  = "t2.micro"
cidr_blocks-subnets = [
  { cidr_block = "10.0.0.0/24", name = "kaseo-public-sub-1" },
  { cidr_block = "10.0.1.0/24", name = "kaseo-public-sub-2" },
  { cidr_block = "10.0.16.0/20", name = "kaseo-private-sub-1" },
  { cidr_block = "10.0.32.0/20", name = "kaseo-private-sub-2" },
  { cidr_block = "10.0.2.0/24", name = "kaseo-private-db-1" },
  { cidr_block = "10.0.3.0/24", name = "kaseo-private-db-2" }
]
