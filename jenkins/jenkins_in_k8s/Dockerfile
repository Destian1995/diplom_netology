FROM jenkins/jenkins:2.387.2-lts-jdk11
USER root

RUN set -x \
	&& curl -fSL "https://download.docker.com/linux/static/stable/x86_64/docker-23.0.3.tgz" -o docker.tgz \
	&& tar -xzvf docker.tgz \
	&& mv docker/* /usr/local/bin/ \
	&& rmdir docker \
	&& rm docker.tgz \
	&& docker -v

RUN set -x \
	&& curl -LO https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl \
	&& install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN set -x \
	&& curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
	&& chmod 700 get_helm.sh \
    && ./get_helm.sh


RUN set -x \
	&& curl -fSL "https://github.com/splunk/qbec/releases/download/v0.15.2/qbec-linux-amd64.tar.gz" -o qbec.gz \
	&& tar xf qbec.gz \
    && mv ./qbec /usr/local/bin/

ENV DOCKER_TLS_CERTDIR=""
ENV DOCKER_DRIVER=overlay2
ENV DOCKER_HOST=tcp://docker:2375