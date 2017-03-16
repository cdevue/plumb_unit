test_install_apache() {
  assert "run_on web_server dpkg -l apache | grep '^ii'"
}

setup() {
  start_instance web_server
  set_group_vars all <<EOF
apache_rpaf_ips: [192.168.109.1, 192.168.109.2]
EOF
}

teardown() {
  destroy()
}

run_ansible() {
  assert "sudo -u rpaulson ansible-playbook --verbose --diff -i 'sample,' /tmp/ansible/playbook.yml"
}


  
