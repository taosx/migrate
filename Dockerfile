FROM golang:1.16-alpine3.13 AS builder

ARG VERSION

ARG USER=default
ENV HOME /home/$USER

ARG USER_ID
ARG GROUP_ID

RUN addgroup -g ${GROUP_ID} -S ${USER} && \
    adduser -u ${USER_ID} -S ${USER} -G ${USER} && \
    chown -R ${USER}:${USER} ${HOME} && \
    apk add --update --no-cache git gcc musl-dev make sudo

USER ${USER}

RUN mkdir ${HOME}/migrate
WORKDIR ${HOME}/migrate

ENV GO111MODULE=on

COPY --chown=${USER}:${USER} go.mod go.sum ./

RUN go mod download

COPY --chown=${USER}:${USER} . ./

RUN mkdir ./build && make build-docker

## Second step

FROM alpine:3.13

ARG USER=default
ENV HOME /home/$USER

ARG USER_ID
ARG GROUP_ID

RUN addgroup -g ${GROUP_ID} -S ${USER} && \
    adduser -u ${USER_ID} -S ${USER} -G ${USER} && \
    chown -R ${USER}:${USER} ${HOME} && \
    apk add --update --no-cache ca-certificates sudo

USER ${USER}

COPY --chown=${USER}:${USER} --from=builder ${HOME}/migrate/build/migrate.linux-386 /usr/local/bin/migrate
RUN ln -s /usr/local/bin/migrate ${HOME}

ENTRYPOINT ["migrate"]
CMD ["--help"]
