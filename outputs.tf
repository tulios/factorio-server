output "ip" {
  value = "${aws_instance.game_server.public_ip}"
}
