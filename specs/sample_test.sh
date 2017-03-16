test_install_apache() {
  assert "run_on web_server dpkg -l apache | grep '^ii'"
}

setup() {
  start_instance web_server

  mkdir /tmp/ansible/group_vars -p

  cat << EOF > /tmp/ansible/playbook.yml
- hosts: all
  roles:
    - role: apache
EOF
}

teardown() {
  destroy()
}

run_ansible() {
  assert "sudo -u rpaulson ansible-playbook --verbose --diff -i 'sample,' /tmp/ansible/playbook.yml"
}


  
