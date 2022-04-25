data "aws_availability_zones" "kk" {}
#define ami

data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["857848422201"]
  filter {
    name   = "name"
    values = ["test-terra-3"]
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
  security_groups     = [aws_security_group.instance-custum-sg.id]
}

resource "aws_autoscaling_group" "kk-auto" {
  name                      = "kk-auto"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.kk-lc.name
  load_balancers            = ["terraform-elb"]
  vpc_zone_identifier       = ["subnet-0e4e67a0dfef65dd4", "subnet-0c37f0dbfffa82e49", "subnet-0f9846331bd6a11a0"]
  tag {
    key = "Name"
    value = "kk-project"
    propagate_at_launch = true
  }
  
}

resource "aws_autoscaling_policy" "custum-cpu-policy" {
  name                   = "custum-cpu-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.kk-auto.name
  policy_type            = "SimpleScaling"
  
}


resource "aws_cloudwatch_metric_alarm" "custum-cpu-alarm" {
  alarm_name          = "custom-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.kk-auto.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
 # alarm_actions     = [aws_autoscaling_group.custum-cpu-alarm.arn]
}



#ELB

# Create a new load balancer
resource "aws_elb" "terra-lb" {
  name               = "terraform-elb"
  availability_zones = ["ap-south-1c", "ap-south-1a", "ap-south-1b"]
  security_groups     = [aws_security_group.elb-custum-sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "terraform-elb"
  }
}

#security group

resource "aws_security_group" "elb-custum-sg" {
  name = "elb-custum-sg"
  description = "elb security group."
  vpc_id = "vpc-04e91fc37dc01032e"
}

resource "aws_security_group_rule" "ssh_ingress_access-2" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.elb-custum-sg.id}"
}

resource "aws_security_group_rule" "http_ingress_access-2" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.elb-custum-sg.id}"
}

resource "aws_security_group_rule" "egress_access-2" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.elb-custum-sg.id}"
}

#isntance-custum-sg

resource "aws_security_group" "instance-custum-sg" {
  name = "instance-custum-sg"
  description = "elb security group."
  vpc_id = "vpc-04e91fc37dc01032e"
}

resource "aws_security_group_rule" "ssh_ingress_access" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.instance-custum-sg.id}"
}

resource "aws_security_group_rule" "http_ingress_access" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.instance-custum-sg.id}"
}

resource "aws_security_group_rule" "egress_access" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.instance-custum-sg.id}"
}
