##############################################################################################################################
#        AWS Provider being used as well as credentials that are goint to be used to establish a connection to AWS           #
##############################################################################################################################
provider "aws" {
  region = var.variable_aws_default_region
  access_key = var.access_key
  secret_key = var.secret_key
}

##############################################################################################################################
#               Spokes VPC Creation with each resource associated with it, such as subnets, and route tables                 #
##############################################################################################################################
##############################################################################################################################
                                                    # VPC Spoke 01
resource "aws_vpc" "SpokeVPC01" {
  cidr_block = var.Variable_Subnet_SpokeVPC01
  tags = {
    Name = "Spoke VPC 01"
  }
}

# Creation of one subnet into VPC Spoke 01
resource "aws_subnet" "Spoke_subnet01" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.SpokeVPC01.id
  cidr_block = var.Variable_Subnet_SpokeVPC01

  tags = {
    Name = "Spoke01 Subnet"
  }
}

# Creation of a route table associated with Spoke01, forwarding all the traffic to the Transit Gateway
resource "aws_default_route_table" "RT_DefaultSpoke01" {
  default_route_table_id = aws_vpc.SpokeVPC01.default_route_table_id
  
  tags = {
    Name = "Route Table Spoke 01"
  }
}

resource "aws_route_table_association" "RT_Spoke01_Association" {
  subnet_id      = aws_subnet.Spoke_subnet01.id
  route_table_id = aws_default_route_table.RT_DefaultSpoke01.id
}

resource "aws_route" "spoke01-igw-route" {
  route_table_id         = aws_default_route_table.RT_DefaultSpoke01.id
  destination_cidr_block = var.Spokes_default_route
  gateway_id             = aws_internet_gateway.IGW_Spoke01.id
  depends_on = [
    aws_internet_gateway.IGW_Spoke01
  ]
}

# Create route to transist gateway in Spoke01 route table 
resource "aws_route" "spoke01-tgw-route" {
  route_table_id         = aws_default_route_table.RT_DefaultSpoke01.id
  destination_cidr_block = var.Spoke01-RT-Spoke02
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
  depends_on = [
    aws_ec2_transit_gateway.TGW
  ]
}
                                                    # End of VPC Spoke 01
##############################################################################################################################
                                                    

##############################################################################################################################
                                                    # VPC Spoke 02
# Creation of VPC Spoke 02
resource "aws_vpc" "SpokeVPC02" {
  cidr_block = var.Variable_Subnet_SpokeVPC02
  tags = {
    Name = "Spoke VPC 02"
  }
}

# Creation of one subnet into VPC Spoke 02
resource "aws_subnet" "Spoke_subnet02" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.SpokeVPC02.id
  cidr_block = var.Variable_Subnet_SpokeVPC02

  tags = {
    Name = "Spoke02 Subnet"
  }
}

# Creation of a route table associated with Spoke02, forwarding all the traffic to the Internet Gateway
resource "aws_default_route_table" "RT_DefaultSpoke02" {
  default_route_table_id = aws_vpc.SpokeVPC02.default_route_table_id
  
  tags = {
    Name = "Route Table Spoke 02"
  }
}

resource "aws_route_table_association" "RT_Spoke02_Association" {
  subnet_id      = aws_subnet.Spoke_subnet02.id
  route_table_id = aws_default_route_table.RT_DefaultSpoke02.id
}

resource "aws_route" "spoke02-igw-route" {
  route_table_id         = aws_default_route_table.RT_DefaultSpoke02.id
  destination_cidr_block = var.Spokes_default_route
  gateway_id             = aws_internet_gateway.IGW_Spoke02.id
  depends_on = [
    aws_internet_gateway.IGW_Spoke02
  ]
}

# Create route to transit gateway in Spoke02 route table 
resource "aws_route" "spoke02-tgw-route" {
  route_table_id         = aws_default_route_table.RT_DefaultSpoke02.id
  destination_cidr_block = var.Spoke02-RT-Spoke01
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
  depends_on = [
    aws_ec2_transit_gateway.TGW
  ]
}

                                                    # End of VPC Spoke 02
##############################################################################################################################

##############################################################################################################################
#           AWS TGW Creation and Attachments properly configured, connecting to both Spokes VPCs and to HUB VPC              #
##############################################################################################################################

# AWS TGW creation
resource "aws_ec2_transit_gateway" "TGW" {
  description = "TGW"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = {
    Name = "TGW"
  }
}

# Attachment of Spoke VPC01 to the TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_Spoke01_Attachment" {
  subnet_ids         = [aws_subnet.Spoke_subnet01.id]
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  vpc_id             = aws_vpc.SpokeVPC01.id
  tags = {
    Name = "TGW_Attachment_Spoke01"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_Spoke02_Attachment" {
  subnet_ids         = [aws_subnet.Spoke_subnet02.id]
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  vpc_id             = aws_vpc.SpokeVPC02.id
  tags = {
    Name = "TGW_Attachment_Spoke02"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_HUB_Attachment" {
  subnet_ids         = [aws_subnet.Security_VPC_trusted_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.TGW.id
  vpc_id             = aws_vpc.Security_VPC.id
  tags = {
    Name = "TGW_Attachment_HUB"
  }
}


resource "aws_internet_gateway" "IGW_Spoke01" {
  vpc_id = aws_vpc.SpokeVPC01.id

  tags = {
    Name = "Internet_GW_Spoke01"
  }
}

resource "aws_internet_gateway" "IGW_Spoke02" {
  vpc_id = aws_vpc.SpokeVPC02.id

  tags = {
    Name = "Internet_GW_Spoke02"
  }
}

resource "aws_internet_gateway" "IGW_HUB" {
  vpc_id = aws_vpc.Security_VPC.id

  tags = {
    Name = "Internet_GW_HUB"
  }
}

##############################################################################################################################
#                              Creation of the AWS Security Groups associated with internal instances                        #
##############################################################################################################################

#Security Groups Creation
# Create SG1

resource "aws_security_group" "SecurityGroup01" {
  name        = "SecurityGroup01"
  description = "allow any internal traffic"
  vpc_id      = aws_vpc.SpokeVPC01.id

  ingress {
    description = "Allow any inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecurityGroup01"
    
  }
}

#SG2
resource "aws_security_group" "SecurityGroup02" {
  name        = "SecurityGroup02"
  description = "allow any internal traffic"
  vpc_id      = aws_vpc.SpokeVPC02.id

  ingress {
    description = "Allow any inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecurityGroup02"
    
  }
}

# Create SecurityGroup to FGT instances

resource "aws_security_group" "SecurityGroup_FGT" {
  name        = "SecurityGroup_FGT"
  description = "allow any internal traffic"
  vpc_id      = aws_vpc.Security_VPC.id

  ingress {
    description = "Allow any inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecurityGroup_FGT"
    
  }
}

#############################################################################################################################
#                                              Create two vms, one in each VPC                                              #
#############################################################################################################################

#Two LAMP Servers to be created
#Use the following credentials:
    #Username: bitnami
    #Authentication key: SpokesInstances-keypair

resource "aws_instance" "instance01" {
  ami                         = var.variable_spokes_instances_AMI
  instance_type               = var.variable_spokes_instances_size
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.Spoke_subnet01.id
  vpc_security_group_ids      = [aws_security_group.SecurityGroup01.id]
  key_name                    = var.variable_spokes_key

  tags = {
    Name = "Instance01"
    }
}


resource "aws_instance" "instance02" {
  ami                         = var.variable_spokes_instances_AMI
  instance_type               = var.variable_spokes_instances_size
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.Spoke_subnet02.id
  vpc_security_group_ids      = [aws_security_group.SecurityGroup02.id]
  key_name                    = var.variable_spokes_key

  tags = {
    Name = "Instance02"
    }
}

resource "aws_instance" "instance03" {
  ami                         = var.variable_spokes_instances_AMI
  instance_type               = var.variable_spokes_instances_size
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.Security_VPC_trusted_subnet.id
  vpc_security_group_ids      = [aws_security_group.SecurityGroup_FGT.id]
  key_name                    = var.variable_spokes_key

  tags = {
    Name = "InstanceTestSecurity"
    }
}

#############################################################################################################################
#                                Create SSH key pair to be used during instances creation                                   #
#############################################################################################################################

#Key Pair
#resource "aws_key_pair" "SpokesInstances-keypair" {
#  key_name   = "SpokesInstances-keypair"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAA.... " # put your public key here
#}


#############################################################################################################################
#                                                Security VPC Settings                                                      #
#############################################################################################################################

##############################################################################################################################
                                                    # VPC Security HUB
# Creation of VPC Security HUB
resource "aws_vpc" "Security_VPC" {
  cidr_block = var.security_vpc_cidr
  tags = {
    Name = "Security VPC"
  }
}

# Creation of MGMT subnet into Security VPC
resource "aws_subnet" "Security_VPC_mgmt_subnet" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.Security_VPC.id
  cidr_block = var.mgmt_subnet_cidr

  tags = {
    Name = "Security VPC - Mgmt Subnet"
  }
}

# Creation of Untrusted subnet into Security VPC
resource "aws_subnet" "Security_VPC_untrusted_subnet" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.Security_VPC.id
  cidr_block = var.untrusted_subnet_cidr

  tags = {
    Name = "Security VPC - Untrusted Subnet"
  }
}

# Creation of Trusted subnet into Security VPC
resource "aws_subnet" "Security_VPC_ha_subnet" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.Security_VPC.id
  cidr_block = var.ha_subnet_cidr

  tags = {
    Name = "Security VPC - HA Sync Subnet"
  }
}

# Creation of Trusted subnet into Security VPC
resource "aws_subnet" "Security_VPC_trusted_subnet" {
  availability_zone = var.variable_aws_default_AZ_1
  vpc_id = aws_vpc.Security_VPC.id
  cidr_block = var.trusted_subnet_cidr

  tags = {
    Name = "Security VPC - Trusted Subnet"
  }
}

# Creation of a route table associated with HUB VPC, with its default route pointing to the Internet GW
resource "aws_default_route_table" "RT_DefaultSecurityHub" {
  default_route_table_id = aws_vpc.Security_VPC.default_route_table_id
  
  tags = {
    Name = "Default RT - Security Hub - IGW"
  }
}

resource "aws_route_table_association" "RT_SecurityHUB_Untrusted_Association" {
  subnet_id      = aws_subnet.Security_VPC_untrusted_subnet.id
  route_table_id = aws_default_route_table.RT_DefaultSecurityHub.id
}

resource "aws_route_table_association" "RT_SecurityHUB_MGMT_Association" {
  subnet_id      = aws_subnet.Security_VPC_mgmt_subnet.id
  route_table_id = aws_default_route_table.RT_DefaultSecurityHub.id
}

resource "aws_route" "HUB-igw-route" {
  route_table_id         = aws_default_route_table.RT_DefaultSecurityHub.default_route_table_id
  destination_cidr_block = var.SecurityHub_default_route
  gateway_id             = aws_internet_gateway.IGW_HUB.id
  depends_on = [
    aws_internet_gateway.IGW_HUB
  ]
}

resource "aws_route_table" "Route_HUB_to_TGW" {
  vpc_id = aws_vpc.Security_VPC.id
  tags = {
    Name = "RT - Security Hub - TGW"
  }
}

resource "aws_route_table_association" "RT_SecurityHUB_trusted_Association" {
  subnet_id      = aws_subnet.Security_VPC_trusted_subnet.id
  route_table_id = aws_route_table.Route_HUB_to_TGW.id
}

# Create route to transit gateway in SecurityHUB route table 
resource "aws_route" "hub-tgw-route-Spoke01" {
  route_table_id         = aws_route_table.Route_HUB_to_TGW.id
  destination_cidr_block = var.Spoke02-RT-Spoke01
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
  depends_on = [
    aws_ec2_transit_gateway.TGW
  ]
}

resource "aws_route" "hub-tgw-route-Spoke02" {
  route_table_id         = aws_route_table.Route_HUB_to_TGW.id
  destination_cidr_block = var.Spoke01-RT-Spoke02
  transit_gateway_id     = aws_ec2_transit_gateway.TGW.id
  depends_on = [
    aws_ec2_transit_gateway.TGW
  ]
}

                                                    # End of VPC Security HUB
##############################################################################################################################

