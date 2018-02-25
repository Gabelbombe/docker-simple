FROM golang:1.9.1-alpine3.6

LABEL maintainer="Ehime <dodomeki@gmail.com>"

ADD . /go/src/github.com/ehime/docker-simple

RUN go install github.com/ehime/docker-simple

EXPOSE 9090

CMD ["/go/bin/app"]
