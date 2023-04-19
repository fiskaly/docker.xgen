#
#   Copyright (C) 2022 fiskaly GmbH <https://fiskaly.com>
#   All rights reserved.
#
#   Developed by: Philipp Paulweber et al.
#   <https://github.com/fiskaly/docker.xgen/graphs/contributors>
#
#   This file is part of docker.xgen.
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.

FROM golang:1.17-alpine \
  AS build

ENV USER=appuser
ENV UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

RUN apk update \
 && apk add --no-cache ca-certificates git \
 && update-ca-certificates

COPY patch_optional_fields.diff .

RUN git clone https://github.com/xuri/xgen \
 && ls -al \
 && cd xgen \
 && git checkout aec4e71118ac79c03e60ede6dee73aa84d8da527 \
 && git apply ../patch_optional_fields.diff \
 && CGO_ENABLED=0 \
    go build -o /go/bin/xgen ./cmd/xgen \
 && /go/bin/xgen -v

FROM scratch \
  AS image

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /go/bin/xgen /xgen

USER appuser:appuser
ENTRYPOINT ["/xgen"]
CMD ["-help"]
