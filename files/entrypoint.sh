#!/bin/bash

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

start() {
    local server_pid
    echo "Starting up PaperMC"
    cat /opt/version.txt

    # Pre-flight checks
    if [ -z "$JAVA_XMS" ]
    then
        echo "Error: JAVA_XMS environment variable not set!"
        exit 1
    fi
    if [ -z "$JAVA_XMX" ]
    then
        echo "Error: JAVA_XMX environment variable not set!"
        exit 1
    fi
    echo -e "\nConfigured Java Xms: ${JAVA_XMS}\nConfigured Java Xmx: ${JAVA_XMX}\n"

    if ! [ -f "/data/server.properties" ]
    then
        echo "Server.properties not found. Creating now for RCON support."
        cp -v /opt/server.properties.default /data/server.properties
    fi

    # Setting RCON password to environment variable.
    sed -i "s/rcon.password=.*/rcon.password=${RCON_PASSWORD}/" /data/server.properties

    # Java flags courtesy of https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/
    java -Xms${JAVA_XMS} -Xmx${JAVA_XMX} -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dlog4j.configurationFile=/opt/log4j2.xml -jar /opt/paper.jar $@ nogui &
    server_pid=$!
    echo $server_pid > /tmp/server_pid
    # Set variables for MCRCON
    export MCRCON_HOST="localhost" MCRCON_PASS="${RCON_PASSWORD}"
    wait $server_pid
}

stop() {
    if ! [ -f /tmp/server_pid ]
    then
        # Server is already being stopped, so don't send commands again.
        return
    fi
    server_pid=$(cat /tmp/server_pid)
    rm /tmp/server_pid
    echo "Signal received. Stopping server through Rcon..."
    mcrcon -p ${RCON_PASSWORD} save-all stop
    wait $server_pid
}

start
