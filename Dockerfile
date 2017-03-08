FROM ubuntu:trusty
MAINTAINER Shaun Jackman <sjackman@gmail.com>

RUN apt-get update \
	&& apt-get install -y curl file g++ git make ruby2.0 ruby2.0-dev uuid-runtime \
	&& ln -sf ruby2.0 /usr/bin/ruby \
	&& ln -sf gem2.0 /usr/bin/gem

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 \
	&& useradd -m -s /bin/bash linuxbrew \
	&& echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
ADD . /home/linuxbrew/.linuxbrew
RUN chown -R linuxbrew: /home/linuxbrew/.linuxbrew \
	&& cd /home/linuxbrew/.linuxbrew \
	&& git remote set-url origin https://github.com/Linuxbrew/brew.git

USER linuxbrew
WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
	USER=linuxbrew
