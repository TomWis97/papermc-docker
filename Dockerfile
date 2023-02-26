FROM alpine:latest
ARG VERSION=latest
ARG BUILD=latest
ENV JAVA_XMS=2G \
    JAVA_XMX=2G \
    RCON_PASSWORD=ChangeMe \
    ENV=/etc/profile
WORKDIR /data
ADD files /opt
RUN apk update && \
    apk add openjdk17-jre jq curl bash rcon && \
    echo getting version && \
    { [ "$VERSION" == "latest" ] && VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]') ; } ; \
    echo "Using PaperMC version $VERSION" && \
    { [ "$BUILD" == "latest" ] && BUILD=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${VERSION}" | jq -r '.builds[-1]') ; } ; \
    echo "Using PaperMC build $BUILD" && \
    filename=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/${VERSION}/builds/${BUILD}" | jq -r '.downloads.application.name') && \
    echo "Discovered filename $filename" && \
    url="https://papermc.io/api/v2/projects/paper/versions/$VERSION/builds/$BUILD/downloads/$filename" && \
    echo "Downloading PaperMC from $url" && \
    curl "$url" > /opt/paper.jar && \
    echo -e "Version: $VERSION\nBuild: $BUILD" > /opt/version.txt && \
    echo "eula=true" > /data/eula.txt && \
    mkdir /logs && \
    adduser minecraft -D -G root && \
    chown -R minecraft:root /data /logs
RUN echo "Compiling MCRCon..." &&\
    apk add make git build-base && \
    git clone https://github.com/tiiffi/mcrcon /tmp/mcrcon && \
    cd /tmp/mcrcon && \
    make && \
    make install && \
    apk del git build-base && \
    rm -rf /tmp/mcrcon && \
    echo 'echo -e "Shell in PaperMC Container.\nUse the mcrcon command for interacting with the server."' >> /etc/profile && \
    echo 'export MCRCON_PASS="$RCON_PASSWORD"' >> /etc/profile
RUN echo "Installing Dinnerbone's mcstatus." && \
    apk add python3 py3-pip && \
    pip3 install mcstatus --ignore-installed six
USER minecraft
EXPOSE 25565 25575
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=10 CMD /usr/bin/mcstatus localhost:25565 status
VOLUME /data /logs
ENTRYPOINT /opt/entrypoint.sh
