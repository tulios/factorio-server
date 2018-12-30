output "ip" {
  value = "${aws_instance.game_server.public_ip}"
}

output "factorio-address" {
  value = "${aws_instance.game_server.public_ip}:34197"
}

output "hostname" {
  value = "${var.aws_host_name}:34197"
}
