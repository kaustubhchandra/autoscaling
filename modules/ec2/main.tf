data "aws_availability_zones" "kk" {}
#define ami

data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["857848422201"]
  filter {
    name   = "name"
    values = ["test-terra-2"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsQtGLI0jIuAQ9qiODdR/L6XQR2OZK3+YnB4/AvAyEtLpLrCMINWCYLl3uPBisxo9O07VJ5V8uV+9/HkfxMKiz4LdhUb4tomXHaUT1G48lQRgZqVbvPEjRs7prG2kBEudbdX4Ayr7ELYOnpHAtQHvPWEwQWnRTN2SzfGLnGQjFBGuydkconMzKQ/+B09wLFIGFj5oe43MTVo62SdSQdQB7WGKE2ueoVxceS5TbLqD7bDGYkAuGQyHjLMZsVQaKQvAkyciw3YvYWifxJML7lv05oQao0o4DvnQOh/Hu3A9gOCJ2LvXPQA6ilDtZCTgSXWjGefjCFTLSmzatTQpOtBwp root@ip-172-31-46-96.ap-south-1.compute.internal"

}

#data "aws_ami" "ubuntu" {
#  most_recent = true

 # filter {
  #  name   = "name"
   # values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
 # }

  #filter {
   # name   = "virtualization-type"
   # values = ["hvm"]
  
#}
 # owners = ["857848422201"] # Canonical
#}

resource "aws_launch_configuration" "kk-lc" {
  name_prefix   = "terraform-lc-example-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "kk-auto" {
  name                      = "kk-auto"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 4
  force_delete              = true
  launch_configuration      = aws_launch_configuration.kk-lc.name
  vpc_zone_identifier       = ["subnet-0e4e67a0dfef65dd4", "subnet-0c37f0dbfffa82e49"]
  tag {
    key = "Name"
    value = "kk-project"
    propagate_at_launch = true
  }
  
}
