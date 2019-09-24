FROM jenkinsci/ssh-slave
MAINTAINER Mikhail Mamaenko <mmamaenko@yahoo.com>
USER root

# Add nodejs, npm, yarn, docker and python with packages
# We may add other packages
ARG DOCKER_VERSION=18.06.1-ce
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    curl -sL https://deb.nodesource.com/setup_12.x | bash - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get update && apt-get install -y curl jq git python2.7 python-pip nodejs &&\
    apt install --no-install-recommends yarn &&\
    apt-get autoremove && apt-get clean && pip install boto3 &&\
    curl -fsSL https://download.docker.com/linux/static/stable/`uname -m`/docker-$DOCKER_VERSION.tgz | tar --strip-components=1 -xz -C /usr/local/bin docker/docker && chmod +x /usr/local/bin/docker
