#!/bin/bash -e

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

docker_image="multimediabs/plumb_unit:centos6"
init=system5
cluster_mode=0

cd $(dirname $0)
test_name=$(basename $(cd ..; pwd))
distrib_name=$(basename $0 | sed -r 's/run_tests_*([^_]*)(_cluster)?.sh/\1/')
grep _cluster <(basename $0) >/dev/null && cluster_mode=1
[ ${cluster_mode} -eq 1 ] && cluster=_cluster
if [ $distrib_name ] 
then
  distrib=_${distrib_name}
  [ "${distrib_name}" == "jessie" ] && docker_image="multimediabs/plumb_unit:debian_jessie" && init=systemd
  [ "${distrib_name}" == "wheezy" ] && docker_image="multimediabs/plumb_unit:debian_wheezy"
  [ "${distrib_name}" == "centos6" ] && docker_image="multimediabs/plumb_unit:centos6"
else
  echo "No distribution specified. Running tests for $(echo ${docker_image} | sed 's/^.*://')"
  distrib=_centos6 # we do not want $distrib_name to be set here
fi

ESCAPE=$(printf "\033")
NOCOLOR="${ESCAPE}[0m"
RED="${ESCAPE}[91m"
GREEN="${ESCAPE}[92m"
YELLOW="${ESCAPE}[93m"
BLUE="${ESCAPE}[94m"

docker_flags_file=".docker_flags"

roles_path="$(readlink -f ../..)"
inside_roles_path="/etc/ansible/roles"
[ ${cluster_mode} -eq 1 ] && inside_roles_path=${roles_path}
inside_tests_path="${inside_roles_path}/${test_name}/tests"

verbose_flag=0
debug_flag=0

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
  tests_list=$(echo $@ | tr ' ' '\n' | sed 's/^/-p /' | xargs)
fi

bash_unit="${inside_tests_path}/bash_unit"
files_with_tests=$(find . | sed '/.*test_'${test_name}'.*'${distrib}${cluster}'$/!d;/~$/d' | sed "s:./:${inside_tests_path}/:g" | xargs)
run_test="${bash_unit} ${tests_list} ${files_with_tests}"

containers=${test_name}
[ ${cluster_mode} -eq 1 ] && containers="${test_name}01 ${test_name}02"

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
  
  [ $init == "systemd" ] && docker_flags="--privileged"
  docker_exec_flags="-i"
  docker_volumes="-v $(cd ${roles_path};pwd):${inside_roles_path}"
  [ ${cluster_mode} -eq 1 ] && docker_volumes=

  [ -t 1 ] && docker_exec_flags="$docker_exec_flags -t"
  docker_flags="$docker_flags $([ -f ${docker_flags_file} ] && cat ${docker_flags_file} || true)"

  for container in ${containers}
  do
    # sad, but if I don't do this and run two times it tries to build while removal in progress.
    docker ps -a | grep ${container} >/dev/null 2>&1 &&  sleep 1
 
    docker ps -a | grep ${container} >/dev/null 2>&1 && docker rm --force ${container} >/dev/null
    eval echo "Running docker with flags [${docker_flags}]" ${output}
    container_id=$(docker run -d ${docker_flags} ${docker_volumes} --name=${container} --hostname=${container} ${docker_image})

    if grep jessie <(echo $distrib_name) >/dev/null
    then
      #wait for systemd to be ready
      while ! docker exec $container systemctl status >/dev/null ; do sleep 1 ; done
      #wait for tmpfiles cleaner to be started so that it does not clean /tmp while tests are running
      while ! docker exec $container systemctl status systemd-tmpfiles-clean.timer >/dev/null ; do sleep 1 ; done
    fi

    if grep wheezy <(echo $distrib_name) >/dev/null
    then
      tst_file=$(docker exec $container mktemp)
      max_wait=10
      while [ ${max_wait} -gt 0 ] ; do
        max_wait=$((max_wait-1))
        [ $(docker exec $container ls ${tst_file} >/dev/null 2>&1 | wc -l ) -eq 0 ] && max_wait=0
        sleep 1
      done
    fi
  done

  for container in ${containers}
  do
    hosts_information=$(echo $(docker inspect -f '{{.NetworkSettings.IPAddress}}' ${container}) ${container})
    for container_dest in ${containers}
    do
      docker exec ${container_dest} /bin/bash -c "echo ${hosts_information} >> /etc/hosts"
    done
  done

  trap "docker rm --force ${containers} >/dev/null" EXIT
  if [ ${cluster_mode} -eq 0 ]
  then
    [ $debug_flag -eq 1 ] && run_test=/bin/bash
    docker exec ${docker_exec_flags} $container /bin/bash -c "exec >/dev/tty 2>/dev/tty </dev/tty ; cd ${inside_tests_path} ; ${run_test}"
    result=$?
  else
    if [ $debug_flag -eq 1 ]
    then
      echo "you're in debug mode"
      echo "once debug done, remove the containers by running the following command :"
      echo "docker rm -f ${containers}"
      trap - EXIT
      run_test="echo -n"
    fi
    ${run_test}
    result=$?
  fi
fi


exit $result
