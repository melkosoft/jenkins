ARG CODE_VERSION=latest
FROM alpine:${CODE_VERSION}

WORKDIR /usr/bin

COPY ngrok run.sh ./
RUN apk update && apk add jq curl &&\
    chmod +x ./ngrok ./run.sh

ENTRYPOINT ["./run.sh"]

