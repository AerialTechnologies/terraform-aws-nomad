# ---------------------------------------------------------------------------------------------------------------------
# THESE TEMPLATES REQUIRE TERRAFORM VERSION 0.8 AND ABOVE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 0.8.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN AUTO SCALING GROUP (ASG) TO RUN NOMAD
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "autoscaling_group" {
  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"

  availability_zones  = ["${var.availability_zones}"]
  vpc_zone_identifier = ["${var.subnet_ids}"]

  # Run a fixed number of instances in the ASG
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  desired_capacity     = "${var.desired_capacity}"
  termination_policies = ["${var.termination_policies}"]

  target_group_arns         = ["${var.target_group_arns}"]
  load_balancers            = ["${var.load_balancers}"]
  health_check_type         = "${var.health_check_type}"
  health_check_grace_period = "${var.health_check_grace_period}"
  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LAUNCH CONFIGURATION TO DEFINE WHAT RUNS ON EACH INSTANCE IN THE ASG
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data     = "${var.user_data}"

  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.name}"
  key_name                    = "${var.ssh_key_name}"
  security_groups             = ["${aws_security_group.lc_security_group.id}"]
  placement_tenancy           = "${var.tenancy}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  ebs_optimized = "${var.root_volume_ebs_optimized}"

  root_block_device {
    volume_type           = "${var.root_volume_type}"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = "${var.root_volume_delete_on_termination}"
  }

  # Important note: whenever using a launch configuration with an auto scaling group, you must set
  # create_before_destroy = true. However, as soon as you set create_before_destroy = true in one resource, you must
  # also set it in every resource that it depends on, or you'll get an error about cyclic dependencies (especially when
  # removing resources). For more info, see:
  #
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  # https://terraform.io/docs/configuration/resources.html
  lifecycle {
    create_before_destroy = true
  }
}
