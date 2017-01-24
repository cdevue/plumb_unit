#!/bin/bash -e

docker_image="multimediabs/plumb_unit:debian_jessie"
docker_image="multimediabs/plumb_unit:centos6"

cd $(dirname $0)
test_name=$(basename $(cd ..; pwd))
distrib_name=$(basename $0 | sed -r 's/run_tests_*(.*).sh/\1/')
if [ $distrib_name ] 
then
  distrib=_${distrib_name}
fi

ESCAPE=$(printf "\033")
NOCOLOR="${ESCAPE}[0m"
RED="${ESCAPE}[91m"
GREEN="${ESCAPE}[92m"
YELLOW="${ESCAPE}[93m"
BLUE="${ESCAPE}[94m"

docker_flags_file=".docker_flags"

role_path="$(readlink -f ..)"
inside_role_path="/etc/ansible/roles/${test_name}"
inside_tests_path="${inside_role_path}/tests"

verbose_flag=0
debug_flag=0

usage() {
  echo "$*
usage: $(basename $0) [-d] [-v] [-h] [test1 test2 ...]
        -d : activates debug mode
        -v : gets verbose (mainly outputs docker outputs)
        -h : this help
        If tests names are passed as arguments, only those will run. Default is to run all tests.
"
  exit
}

format() {
  local color=$1
  shift
  if [ -t 1 ] ; then echo -en "$color" ; fi
  if [ $# -gt 0 ]
  then
    [[ $verbose_flag -eq 0 ]] && echo $*
  else
    [[ $verbose_flag -eq 0 ]] && cat
  fi
  if [ -t 1 ] ; then echo -en "$NOCOLOR" ; fi
}

while getopts vhdp name
do
  case $name in
    v)
      verbose_flag=1
      ;;
    d)
      debug_flag=1
      ;;
    h)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

[ $verbose_flag -eq 0 ] && output=">/dev/null 2>&1" || output="2>&1"

if [ $# -gt 0 ] ; then
  tests_list=$(echo $@ | tr ' ' '\n' | sed 's/^/-p /' | xargs echo)
fi

bash_unit="${inside_tests_path}/bash_unit"
run_test="${bash_unit} ${tests_list} ${inside_tests_path}/test_${test_name}${distrib}"

if [ -f /.dockerenv -a $(id -u) -eq 0 ]
then
  ${run_test}
else
  if [ -f Dockerfile ]
  then
    format ${BLUE} -n "Building ${test_name} ${docker_build_flags} container..."
    eval docker build -t ${test_name} ${docker_build_flags} . ${output} || exit 42
    format ${GREEN} "DONE"
  fi
  
#  docker_flags="--privileged"
  docker_exec_flags="-i"
  docker_volumes="-v $(cd ${role_path};pwd):${inside_role_path}"

  [ -t 1 ] && docker_exec_flags="$docker_exec_flags -t"
  docker_flags="$docker_flags $([ -f ${docker_flags_file} ] && cat ${docker_flags_file} || true)"

  eval echo "Running docker with flags [${docker_flags}]" ${output}
  container=$(docker run -d ${docker_flags} ${docker_volumes} ${docker_image})
  trap "docker rm --force $container >/dev/null" EXIT

  #wait for init to startup at most for 2 second and go on, whatever happens
  timeout 2 /bin/bash -c "while ! docker exec -i $container systemctl status >/dev/null ; do echo -n ; done" || true

  if [ $debug_flag -eq 1 ]
  then
    docker exec ${docker_exec_flags} $container /bin/bash -c "exec >/dev/tty 2>/dev/tty </dev/tty ; /bin/bash"
  else
    docker exec ${docker_exec_flags} $container /bin/bash -c "exec >/dev/tty 2>/dev/tty </dev/tty ; ${run_test}"
    result=$?
  fi
fi


exit $result
