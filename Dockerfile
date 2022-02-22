FROM alpine:3.14
RUN apk add --no-cache build-base cmake bsd-compat-headers m4 luajit luajit-dev openssl openssl-dev zlib zlib-dev curl git unzip

RUN cd /tmp && \
    git clone --depth=1 https://github.com/keplerproject/luarocks.git && \
    cd luarocks && \
    sh ./configure && \
    make build install && \
    cd && \
    rm -rf /tmp/luarocks

RUN luarocks install rapidjson
RUN luarocks install lua-zlib
RUN luarocks install http
RUN mkdir app
ADD src app/src
ADD build.sh app/build.sh
ADD start.sh app/start.sh
RUN chmod +x app/start.sh
RUN app/build.sh
RUN ls app

WORKDIR app
CMD ["/app/start.sh"]
