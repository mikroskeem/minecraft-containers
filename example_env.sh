if [ -f .update ]; then
    echo ">>> Downloading new Paper"
    curl -o paper-latest.jar https://papermc.io/api/v1/paper/1.15.2/latest/download
    rm .update
fi

if [ -f paper-*.jar ]; then
    mv -v paper-*.jar server.jar || {
        echo ">>> ERROR: unable to move '" paper-*.jar "' to server.jar, multiple files matching the pattern?"
        exit 1
    }
fi

LD_PRELOAD=/opt/mimalloc/libmimalloc.so
export LD_PRELOAD
