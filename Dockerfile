FROM ubuntu:xenial
LABEL maintainer="Shaun Jackman <sjackman@gmail.com>"

RUN apt-get update \
	&& apt-get install -y curl file g++ git locales make uuid-runtime

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 \
	&& useradd -m -s /bin/bash linuxbrew \
	&& echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
ADD . /home/linuxbrew/.linuxbrew/Homebrew
RUN mkdir /home/linuxbrew/.linuxbrew/bin \
	&& ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/ \
	&& chown -R linuxbrew: /home/linuxbrew/.linuxbrew \
	&& cd /home/linuxbrew/.linuxbrew/Homebrew \
	&& git remote set-url origin https://github.com/Linuxbrew/brew.git

USER linuxbrew
WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
	USER=linuxbrew
