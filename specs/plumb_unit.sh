start_instance() {
  #Start a new computer under test
  #This new instance can be referenced by the given name
  #The base image of this new instance will be selected
  #according to the given os_type.
  #You must ensure that you destroy all the instances you
  #creates. Otherwise you will encounter virtualization or
  #containerization resources leaks. 
  local name=$1
  local os_type=$2
}

destroy_instance() {
  #destroys a computer under test
  #the instance identified by name is destroyed
  local name=$1
}

destroy() {
  #Destroys all the instances of all computer under test
  #created by the current program (what is a program ?).
}

run_on() {
  #Runs the given command on the given instance.
  #The instance of the computer under test to run the command
  #on is specified by the given name.
  #all other parameters are part of the command.
  #
  #The exit status of this function is the exit status of the
  #command ran on instance named <name>.
  #
  #The standard output and standard error of this function are
  #the standard output and standard error of the command ran
  #on the instance named <name>
  local name=$1
  shift
  local command="$*"
}
