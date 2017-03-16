test_install_packages() {
  assert "run_on sample dpkg -l sample | grep '^ii'"
}

setup() {
  start_instance sample

  mkdir /tmp/ansible/group_vars -p

  cat << EOF > /tmp/ansible/playbook.yml
- hosts: all
  roles:
    - role: sample
EOF
}

run_ansible() {
  assert "sudo -u rpaulson ansible-playbook --verbose --diff -i 'sample,' /tmp/ansible/playbook.yml"
}


  
