FROM debian:buster-slim

MAINTAINER cc_doc_nfc.oab@orange.com <cc_doc_nfc.oab@orange.com>

ENV container docker
ENV DEBIAN_FRONTEND noninteractive

### Packages installation layer
RUN apt-get update && apt-get -y dist-upgrade ; \
    apt-get install -y systemd-sysv systemd initscripts ; \
    apt-get install -y aptitude iproute2 locales git sudo vim net-tools curl lsb-release ; \
    apt-get install -y libffi-dev libssl-dev libyaml-dev ; \
    apt-get install -y python python-crypto python-openssl python-dev python-pip python-apt; \
    apt-get remove -y manpages manpages-dev ; \
    apt-get clean

### Secure container running as privileged
RUN ( \
      cd /lib/systemd/system/sysinit.target.wants/ && \
      rm -f $(ls | grep -v systemd-tmpfiles-setup.service) \
    ) ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ; \
    rm -f /etc/systemd/system/*.wants/* ; \
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ;\
    rm -f /lib/systemd/system/anaconda.target.wants/* ;\
    rm -f /usr/lib/tmpfiles.d/systemd-nologin.conf ; \
    rm -f /lib/systemd/system/systemd*udev* ; \
    rm -f /lib/systemd/system/getty.target

### Ansible installation with pip and optimize first run of apt ansible module
RUN pip install --no-cache-dir --upgrade setuptools ; \
    pip install --no-cache-dir --upgrade PyYAML dnspython pyOpenSSL pyasn1 jinja2 paramiko ansible
RUN ansible -i localhost, -c local all -m apt -a "update_cache=yes"

### System configuration
ADD files/locale.gen /etc/locale.gen
RUN locale-gen
ENV LANG fr_FR.UTF-8
ENV TERM xterm
RUN for i in $(seq 1 8) ; do mkdir -p /usr/share/man/man$i ; done;

### Add a local user to avoid running ansible as root. This user has a name
RUN useradd -ms /bin/bash -c "Robert Paulson" rpaulson
RUN echo "rpaulson ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/rpaulson

### Enable docker in docker
RUN set -x && \
    addgroup --system dockremap && \
    adduser --system --group dockremap && \
    echo 'dockremap:165536:65536' >> /etc/subuid && \
    echo 'dockremap:165536:65536' >> /etc/subgid
ENV DIND_COMMIT 3b5fac462d21ca164b3778647420016315289034
RUN curl -o /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" \
    && chmod +x /usr/local/bin/dind
EXPOSE 2375

### Start systemd, be a system
CMD ["/lib/systemd/systemd"]
