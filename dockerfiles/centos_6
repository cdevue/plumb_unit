FROM centos:6

MAINTAINER cc_doc_nfc.oab@orange.com <cc_doc_nfc.oab@orange.com>

VOLUME [ "/sys/fs/cgroup" ]

ENV container docker

RUN yum -y update; yum clean all
RUN yum install -y sudo vim git epel-release
RUN yum install -y ansible

# Add a local user to avoid running ansible as root. This user has a name
RUN useradd -ms /bin/bash -c "Robert Paulson" rpaulson
RUN echo "rpaulson ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/rpaulson

CMD ["/sbin/init"]
