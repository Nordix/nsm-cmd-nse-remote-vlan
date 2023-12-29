FROM golang:1.20.11 as go
ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOBIN=/bin
RUN go install github.com/grpc-ecosystem/grpc-health-probe@v0.4.12
RUN go install github.com/go-delve/delve/cmd/dlv@v1.8.2
ADD https://github.com/spiffe/spire/releases/download/v1.2.2/spire-1.2.2-linux-x86_64-glibc.tar.gz .
RUN tar xzvf spire-1.2.2-linux-x86_64-glibc.tar.gz -C /bin --strip=2 spire-1.2.2/bin/spire-server spire-1.2.2/bin/spire-agent

FROM go as build
WORKDIR /build
COPY . .
RUN go build -o /bin/app .

FROM build as test
CMD go test -test.v ./...

FROM test as debug
CMD dlv -l :40000 --headless=true --api-version=2 test -test.v ./...

FROM alpine as runtime
COPY --from=build /bin/app /bin/app
COPY --from=build /bin/grpc-health-probe /bin/grpc-health-probe
RUN ln -s /bin/grpc-health-probe /bin/grpc_health_probe
CMD /bin/app