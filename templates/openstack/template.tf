resource "openstack_compute_floatingip_v2" "main" {
  pool = "public"
}

resource "openstack_compute_secgroup_v2" "web_security_group" {
  name = "WebSecurityGroup"
  description = "Enable SSH access, HTTP access via port 80"
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "ap_security_group" {
  name = "APSecurityGroup"
  description = "Enable SSH access and HTTP access via port 8080"
  rule {
    from_port = 8080
    to_port = 8080
    ip_protocol = "tcp"
    from_group_id = "${openstack_compute_secgroup_v2.web_security_group.id}"
  }
}

resource "openstack_compute_secgroup_v2" "db_security_group" {
  name = "DBSecurityGroup"
  description = "Enable SSH access and DB access via port 3306"
  rule {
    from_port = 3306
    to_port = 3306
    ip_protocol = "tcp"
    from_group_id = "${openstack_compute_secgroup_v2.ap_security_group.id}"
  }
}

resource "openstack_compute_instance_v2" "web_server" {
  name = "WebServer"
  image_id = "${var.web_image}"
  flavor_name = "${var.web_instance_type}"
  metadata {
    Role = "web"
    Name = "WebServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.web_security_group.name}", "${var.shared_security_group}"]
  floating_ip = "${openstack_compute_floatingip_v2.main.address}"
  network {
    uuid = "${element(split(", ", var.subnet_ids), 0)}"
  }
}

resource "openstack_compute_instance_v2" "ap_server" {
  depends_on = ["openstack_compute_instance_v2.web_server"]
  name = "APServer"
  image_id = "${var.ap_image}"
  flavor_name = "${var.ap_instance_type}"
  metadata {
    Role = "ap"
    Name = "APServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.ap_security_group.name}", "${var.shared_security_group}"]
  network {
    uuid = "${element(split(", ", var.subnet_ids), 0)}"
  }
}

resource "openstack_compute_instance_v2" "db_server" {
  depends_on = ["openstack_compute_instance_v2.web_server"]
  name = "DBServer"
  image_id = "${var.db_image}"
  flavor_name = "${var.db_instance_type}"
  metadata {
    Role = "db"
    Name = "DBServer"
  }
  key_pair = "${var.key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.db_security_group.name}", "${var.shared_security_group}"]
  network {
    uuid = "${element(split(", ", var.subnet_ids), 0)}"
  }
}

output "cluster_addresses" {
  value = "${openstack_compute_instance_v2.web_server.network.0.fixed_ip_v4}, ${openstack_compute_instance_v2.ap_server.network.0.fixed_ip_v4}, ${openstack_compute_instance_v2.db_server.network.0.fixed_ip_v4}"
}

output "consul_addresses" {
  value = "${openstack_compute_floatingip_v2.main.address}"
}

output "frontend_addresses" {
  value = "${openstack_compute_floatingip_v2.main.address}"
}
