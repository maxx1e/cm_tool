FROM debian:stable-slim

# Build Arguments (keep in mind that only 2.0.1 is working with Solution Manager)
ARG CM_VERSION=2.0.1
ARG JAVA_KEYSTORE=cacerts
ARG JAVA_KEYSTORE_PWD=changeit
# Run environment and shell
ENV ROOT_CERT="root.cer"
ENV INTER_CERT="inter.cer"
ENV HOST_CERT="srv.cer"
ENV CM_HOME=/opt/sap
ENV CM_USER_HOME=/home/cmtool
ENV CMCLIENT_OPTS="-Djavax.net.ssl.trustStore=/usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
# Image issue while JRE installation (https://github.com/debuerreotype/docker-debian-artifacts/issues/24)
RUN mkdir -p /usr/share/man/man1
# Update repo and install JRE (openjdk images has problems with cert path)
RUN apt-get update && apt-get install -y --no-install-recommends curl jq openjdk-11-jre-headless && \
    rm -rf /var/lib/apt/lists/*
# Install yq processing tool
RUN curl -LJO https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod a+rx yq_linux_amd64 && \
    mv yq_linux_amd64 /opt/yq && \
    ln -sf /opt/yq /bin/yq
# Handle user permissions
RUN echo "[INFO] Handle users permission." && \
    useradd --home-dir "${CM_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1000 --comment 'DevOps CM tool' --password "$(echo weUseCm |openssl passwd -1 -stdin)" cmtool && \
    # Allow anybody to write into the images HOME
    chmod a+w "${CM_USER_HOME}"
# Copy certs chain. Can be commented, and than volume attached to this path. Uncomment if required
#COPY /certs "${CM_USER_HOME}"
# Download CM client and install LICENSE
RUN echo "[INFO] Install CM clinet $CM_VERSION." && \
    mkdir -p "${CM_HOME}" && \
    curl --silent --show-error "https://repo1.maven.org/maven2/com/sap/devops/cmclient/dist.cli/${CM_VERSION}/dist.cli-${CM_VERSION}.tar.gz" | tar -xzf - -C "${CM_HOME}" && \
    curl --silent --show-error --output ${CM_HOME}/LICENSE "https://raw.githubusercontent.com/SAP/devops-cm-client/master/LICENSE" && \
    chown -R root:root "${CM_HOME}" && \
    ln -s "${CM_HOME}/bin/cmclient" "/usr/local/bin/cmclient"
# Install certs. However instead of using COPY instruction. it is possible to provide path via docker volume. Uncomment if required
#RUN echo "[INFO] Install certificates in the JRA truststore." && \
#    keytool -import -trustcacerts -noprompt -keystore "${JAVA_HOME}/lib/security/cacerts" -storepass changeit -alias "${HOST_CERT%.*}" -file "${CM_USER_HOME}/${HOST_CERT}" && \
#    keytool -import -trustcacerts -noprompt -keystore "${JAVA_HOME}/lib/security/cacerts" -storepass changeit -alias "${INTER_CERT%.*}" -file "${CM_USER_HOME}/${INTER_CERT}" && \
#    keytool -import -trustcacerts -noprompt -keystore "${JAVA_HOME}/lib/security/cacerts" -storepass changeit -alias "${ROOT_CERT%.*}" -file "${CM_USER_HOME}/${ROOT_CERT}"
WORKDIR $CM_HOME/bin
