ARG UPSTREAM_IMAGE_TAG
ARG UPSTREAM_RELEASE_TAG

# Rebuild the upstream binary with the Home Assistant Ingress auth patch.
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder

ARG UPSTREAM_RELEASE_TAG
ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache ca-certificates git
RUN git clone --depth 1 --branch "${UPSTREAM_RELEASE_TAG}" \
      https://github.com/jeessy2/ddns-go.git /src
WORKDIR /src
COPY patches/ha-ingress-auth.patch /tmp/ha-ingress-auth.patch
RUN git apply --ignore-space-change /tmp/ha-ingress-auth.patch \
    && gofmt -w web/auth.go web/save.go
RUN CGO_ENABLED=0 GOOS="${TARGETOS:-linux}" GOARCH="${TARGETARCH:-amd64}" \
    go build -trimpath -ldflags "-s -w -X main.version=${UPSTREAM_RELEASE_TAG}" -o /ddns-go .

# Keep the upstream runtime image and replace only its binary.
FROM ghcr.io/jeessy2/ddns-go:${UPSTREAM_IMAGE_TAG}

RUN apk add --no-cache jq

COPY --from=builder /ddns-go /app/ddns-go
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT ["/run.sh"]
