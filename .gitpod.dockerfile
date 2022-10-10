############################################################################################
#            DO NOT EDIT THIS DOCKER FILE AND PUSH. THIS IS CUSTOM MADE DOCKER.            #
############################################################################################
FROM gitpod/workspace-full

ENV PATH=/usr/lib/dart/bin:$PATH

USER root

# Downloading the dart sdk from the internet
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list \
    && install-packages build-essential dart libkrb5-dev gcc make

# Setting up environment according to the project.
RUN set -ex; \
    dart --version; \
    dart --disable-analytics
