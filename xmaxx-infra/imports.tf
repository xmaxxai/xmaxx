import {
  to = aws_vpc.project
  id = "vpc-090d36edff56261a5"
}

import {
  to = aws_internet_gateway.project
  id = "igw-0a8399c790bfae19e"
}

import {
  to = aws_subnet.public_2a
  id = "subnet-0785d3543276a4d6b"
}

import {
  to = aws_subnet.public_2b
  id = "subnet-0d930bde3ed6c158c"
}

import {
  to = aws_subnet.misc_2b
  id = "subnet-0c7f3a62289333f34"
}

import {
  to = aws_subnet.private_2a
  id = "subnet-02a1eab7ddf970f53"
}

import {
  to = aws_subnet.private_2b
  id = "subnet-07fd4e9e82ede9710"
}

import {
  to = aws_route_table.public
  id = "rtb-07b4702cd61a7e935"
}

import {
  to = aws_route_table.private_2a
  id = "rtb-0200fefad7fbfe48b"
}

import {
  to = aws_route_table.private_2b
  id = "rtb-0a844fed8fe778c54"
}

import {
  to = aws_route.public_default
  id = "rtb-07b4702cd61a7e935_0.0.0.0/0"
}

import {
  to = aws_route_table_association.public_2a
  id = "subnet-0785d3543276a4d6b/rtb-07b4702cd61a7e935"
}

import {
  to = aws_route_table_association.public_2b
  id = "subnet-0d930bde3ed6c158c/rtb-07b4702cd61a7e935"
}

import {
  to = aws_route_table_association.private_2a
  id = "subnet-02a1eab7ddf970f53/rtb-07b4702cd61a7e935"
}

import {
  to = aws_route_table_association.private_2b
  id = "subnet-07fd4e9e82ede9710/rtb-0a844fed8fe778c54"
}

import {
  to = aws_vpc_endpoint.s3_gateway
  id = "vpce-0c40852e415100faf"
}

import {
  to = aws_security_group.launch_wizard_1
  id = "sg-0d595bc8be1aeaa95"
}

import {
  to = aws_default_security_group.default
  id = "sg-03d3b32c861693d1c"
}

import {
  to = aws_instance.xmaxx
  id = "i-0b8c6eb90077f5217"
}
