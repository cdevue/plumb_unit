source plumb_unit.sh

test_install_apache() {
  assert "run_on web_server dpkg -l apache | grep '^ii'"
}

setup() {
  set_group_vars all <<EOF
apache_rpaf_ips: [192.168.109.1, 192.168.109.2]
EOF
  start_instance web_server
  run_ansible
}

teardown() {
  destroy()
}
