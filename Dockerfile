FROM openjdk:8-jre-slim

# Build Arguments (keep in mind that only 2.0.1 is working with Solution Manager)
ARG CM_VERSION=2.0.1
ARG CM_USER_HOME=/home/cmtool

# Run environment and shell
ENV CM_HOME=/opt/sap/cmclient
ENV CMCLIENT_OPTS="-Dcom.sun.net.ssl.checkRevocation=false"
RUN echo "[INFO] handle users permission." && \
    useradd --home-dir "${CM_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1000 --comment 'DevOps CM tool' --password "$(echo weUseCm |openssl passwd -1 -stdin)" cmtool && \
    # Allow anybody to write into the images HOME
    chmod a+w "${CM_USER_HOME}"
# Update repo
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Download CM client and install LICENSE
RUN echo "[INFO] Install CM clinet $CM_VERSION." && \
    mkdir -p "${CM_HOME}" && \
    curl --silent --show-error "https://repo1.maven.org/maven2/com/sap/devops/cmclient/dist.cli/${CM_VERSION}/dist.cli-${CM_VERSION}.tar.gz" | tar -xzf - -C "${CM_HOME}" && \
    curl --silent --show-error --output ${CM_HOME}/LICENSE "https://raw.githubusercontent.com/SAP/devops-cm-client/master/LICENSE" && \
    chown -R cmtool:cmtool "${CM_HOME}" && \
    ln -s "${CM_HOME}/bin/cmclient" "/usr/local/bin/cmclient"

WORKDIR $CM_HOME/bin
USER cmtool
