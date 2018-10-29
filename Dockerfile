FROM ubuntu:xenial
LABEL maintainer="Shaun Jackman <sjackman@gmail.com>"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends software-properties-common \
	&& add-apt-repository -y ppa:git-core/ppa \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		curl \
		file \
		fonts-dejavu-core \
		g++ \
		git \
		locales \
		make \
		openssh-client \
		patch \
		sudo \
		uuid-runtime \
	&& rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 \
	&& useradd -m -s /bin/bash linuxbrew \
	&& echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
ADD . /home/linuxbrew/.linuxbrew/Homebrew
RUN cd /home/linuxbrew/.linuxbrew \
	&& mkdir -p bin etc include lib opt sbin share var/homebrew/linked Cellar \
	&& ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/ \
	&& chown -R linuxbrew: /home/linuxbrew/.linuxbrew \
	&& cd /home/linuxbrew/.linuxbrew/Homebrew \
	&& git remote set-url origin https://github.com/Homebrew/brew

USER linuxbrew
WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
	SHELL=/bin/bash \
	USER=linuxbrew

# Install portable-ruby and tap homebrew/core.
RUN HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 brew tap homebrew/core \
	&& rm -rf ~/.cache
