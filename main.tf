locals {
  user_data = <<EOF
#!/bin/bash
sudo su

yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "hello world from $(hostname -f) >> /var/www/html/index.html
EOF
}



module "vpc" {
    count=length(var.vpc_cidrs)
    source = "terraform-aws-modules/vpc/aws"

    name = format("duy-vpc-%d",count.index)
    cidr = "${var.vpc_cidrs[count.index]}"
    azs=["us-east-1a","us-east-1b","us-east-1c"]
    public_subnets = "${var.subnet_cidrs[count.index]}"

    enable_nat_gateway = false
    # single_nat_gateway = false
    # reuse_nat_ips      = true
    # external_nat_ip_ids =    "${aws_eip.nat.*.id}"

    tags = {
        terraform = "true"
        Environment = "dev"
    }
}


data "aws_subnet_ids" "public" {
  count = length(var.vpc_cidrs)
  vpc_id = "${module.vpc[count.index].vpc_id}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
}

module "security_group" {
  count = length(var.vpc_cidrs)
  source = "terraform-aws-modules/security-group/aws"

  name        = format("http_icmp_ssh_%d",count.index)
  description = "Security group for example usage with EC2 instance"
  vpc_id      = "${module.vpc[count.index].vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

module "ec2_cluster" {
  source = "terraform-aws-modules/ec2-instance/aws"

  count = length(var.vpc_cidrs)
  # for_each = data.aws_subnet_ids.public[count.index].ids 
  name                        = format("example_%d",count.index)
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${tolist(data.aws_subnet_ids.public[count.index].ids)[count.index]}"
  vpc_security_group_ids      = ["${module.security_group[count.index].security_group_id}"]
  associate_public_ip_address = true
  user_data_base64 = base64encode(local.user_data)
  key_name = aws_key_pair.dytn.key_name
}

resource "aws_eip" "lterb" {
  count = length(module.ec2_cluster)
  instance = module.ec2_cluster[count.index].id[0]
  vpc      = true
}

resource "aws_key_pair" "dytn" {
    key_name = "dytn-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeskIzxuKiWySyiNRRFt22M9J++Ne4KaDAZL/a4PpaOTeNRJVitKq/raGwtwjEZU0CeP04DBXkN2rbffg8KDExNGm8BuXXwwbCKQ/xEnRzusY446Jg/FF88cs2OeknbSYADMb2vc0IzxQs9KEjdyAGXObJrxMRuopxRSdW/yGd8tlr48i7BMTNj/NKCxIoyucqRZxPPzFbEPzu2oXCmjDIef4f2ujxpuqxPZxAkztHNEmR184x91m9TZF5IDtjeHHPpXPQQKRJMx/X0Xbp98CvDi2jdDz3YV2rrbsOQricKVbTHqdmiEQuNTsnmN3JVsDT2zGNWzr4ImA5BCnhvGKAABAz71wylQcaHziZI6RojkkV/icAqn2ijzdiqxRJyQ8oRtFlN1hzSdEI4rAUn40nS8Le+6C/eky4I9OjriaihKYU8KSIkCm+byKDEiT9EAJlcZ7T+TQV57ljkw1NY9+9s89XV7t7zG82ofEnr3A4nxZk/U5frSqYO1Gl7TO3NYCHkpxUKHpGJFkTRkXooS8KrC1OvSOYtCzz0Hg2fOF/q968ncv90tMelZ8xy1TKsqWAZBASQx122m03Nc7rke17TLEG1dBUMxVVk6O1nQgAPKIZWDRmyHlDWesYet4MPfcT4DcCDxyDpLIdfRMkwuNcJYxF6EU5BnUB8JlnNumAnw== dytn@gft.com"
}
resource "aws_key_pair" "duy_tran" {
  key_name = "duy.tran"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcuMjTq8pM/4sjNx37OwOmz2fTjxe5Isr2hIpQ6osHEPjKs8KbFFTGi3rUpVrENhL6ZNg7vjoa3jvIK4iJEON9CaAtfA8U1nHfYI/rB1xRhYFfu6oTxkqWtozY+3ONt0vbXGM5JVd+AhMnWy3PrUS50v0h6xT7n7NLF2nQAGhniS2zlXbjjMs/541GFxTCXzBY51rFi4+oL8YKSpVNCUmuSXrmW0mLxU3YCv56w4N3uk6dUzox3TNLW+qMiSxEH6nocPS6Y9gPs3utzGKTbyKQMg5ZBaqoyhO+P5RDXz8DCr4Q8FXGxkzgZSXiH3RiecyztDhbJTDj/E7idCuiwzubgmIZ8KOj8MPYr6pI6AMY6Uqxxs9tLxMzIORAATtyYjXe3DiAYvRyz/EbLtZwLfrCjuaqmtJwzGG36ERnOp/zTB28wtMxhMQYAUaRMpePtuCrbN/l1t1siCMOdYOM4JM1TeZ0Vd8CK4NEzdKG5eHXUUt4n4BOE9KWDa5f0BoTmndBNKLl3lq6IrVAsXr0jmAxzzDIItHuhR3tAU97n9gSkEgLXE6TQFqmpDhK4FKSpPZuQ6pQN/gDQkjF/X7nRZAJpiF4I8yco35nCIisbCmyQAlAm0lpQfR9/me+WZ0sKAd8NcXyZaadmAkA4rICxEKMZsnwIn3MTjqKmhB8znbR3Q== duy.tran@prjphx.com"
  
}