FROM debian:jessie

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.8
ENV HAPROXY_MD5 8cb3719013e7f34c6d689dabf8a8cd6e

ENV LIBSLZ_VERSION v1.0.0
# No md5 for libslz yet -- the tarball is dynamically
# generated and it differs every time.

ENV PCRE_VERSION 8.39
ENV PCRE_MD5 26a76d97e04c89fe9ce22ecc1cd0b315

ENV LIBRESSL_VERSION 2.2.9
ENV LIBRESSL_MD5 469e9c9c5d5cd540af2e0ded3ca06d8a

ENV LUA_VERSION=5.3.2
ENV LUA_MD5=33278c2ab5ee3c1a875be8d55c1ca2a1

ENV LUAROCKS_VERSION=2.3.0
ENV LUAROCKS_MD5=a38126684cf42b7d0e7a3c7cf485defb

RUN buildDeps='make file libc-dev libreadline-dev' \
    set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y ${buildDeps} && \

    # binaries that lunarocks needs to operate

    apt-get install --no-install-recommends -y gcc unzip curl && \

    # SLZ

    curl -OJ "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=v1.0.0;sf=tgz" && \
    tar zxvf libslz-${LIBSLZ_VERSION}.tar.gz && \
    make -C libslz static && \

    # PCRE

    curl -OJ "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz" && \
    echo ${PCRE_MD5} pcre-${PCRE_VERSION}.tar.gz | md5sum -c && \
    tar zxvf pcre-${PCRE_VERSION}.tar.gz && \
    cd pcre-${PCRE_VERSION} && \

    CPPFLAGS="-D_FORTIFY_SOURCE=2" \
    LDFLAGS="-fPIE -pie -Wl,-z,relro -Wl,-z,now" \
    CFLAGS="-pthread -g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wall -fvisibility=hidden" \
    ./configure --prefix=/tmp/pcre --disable-shared --enable-utf8 --enable-jit --enable-unicode-properties --disable-cpp && \
    make install && \
    ./pcre_jit_test && \
    cd .. && \

    # LibreSSL

    curl -OJ http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz && \
    echo ${LIBRESSL_MD5} libressl-${LIBRESSL_VERSION}.tar.gz | md5sum -c && \
    tar zxvf libressl-${LIBRESSL_VERSION}.tar.gz && \
    cd libressl-${LIBRESSL_VERSION} && \
    ./configure --disable-shared --prefix=/tmp/libressl && \
    make check && \
    make install && \
    cd .. && \

    # Lua

    curl -OJ http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz && \
    echo ${LUA_MD5} lua-${LUA_VERSION}.tar.gz | md5sum -c && \
    tar zxf lua-${LUA_VERSION}.tar.gz && \
    cd lua-${LUA_VERSION} && \
    make linux && \
    make install && \
    cd .. && \

    # Lua package manager

    curl -OJL http://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz && \
    echo ${LUAROCKS_MD5} luarocks-${LUAROCKS_VERSION}.tar.gz | md5sum -c && \
    tar zxvf luarocks-${LUAROCKS_VERSION}.tar.gz && \
    cd luarocks-${LUAROCKS_VERSION} && \
    ./configure && \
    make bootstrap && \
    cd .. && \

    # HAProxy

    curl -OJL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" && \
    echo "${HAPROXY_MD5} haproxy-${HAPROXY_VERSION}.tar.gz" | md5sum -c && \
    tar zxvf haproxy-${HAPROXY_VERSION}.tar.gz && \
    make -C haproxy-${HAPROXY_VERSION} \
      TARGET=linux2628 \
      USE_SLZ=1 SLZ_INC=../libslz/src SLZ_LIB=../libslz \
      USE_STATIC_PCRE=1 USE_PCRE_JIT=1 PCREDIR=/tmp/pcre \
      USE_OPENSSL=1 SSL_INC=/tmp/libressl/include SSL_LIB=/tmp/libressl/lib \
      USE_LUA=1 \
      all \
      install-bin && \
    mkdir -p /usr/local/etc/haproxy && \
    cp -R haproxy-${HAPROXY_VERSION}/examples/errorfiles /usr/local/etc/haproxy/errors && \

    # Clean up
    rm -rf /var/lib/apt/lists/* /tmp/* haproxy* pcre* libressl* libslz* && \
    apt-get purge -y --auto-remove ${buildDeps}


CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
