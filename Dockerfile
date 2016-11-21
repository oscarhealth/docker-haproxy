FROM debian:jessie

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.10
ENV HAPROXY_MD5 6d47461c008b823a0088d19ec30dbe4e

ENV LIBSLZ_VERSION 1.1.0
# No md5 for libslz yet -- the tarball is dynamically
# generated and it differs every time.

ENV PCRE_VERSION 8.39
ENV PCRE_MD5 26a76d97e04c89fe9ce22ecc1cd0b315

ENV OPENSSL_VERSION 1.1.0c
ENV OPENSSL_SHA256 fc436441a2e05752d31b4e46115eb89709a28aef96d4fe786abe92409b2fd6f5

RUN buildDeps='curl gcc make file libc-dev perl' \
    set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y ${buildDeps} && \

    # SLZ

    curl -OJ "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=v${LIBSLZ_VERSION};sf=tgz" && \
    tar zxvf libslz-v${LIBSLZ_VERSION}.tar.gz && \
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

    # OpenSSL (LibreSSL support removed due to API ambiguity, see: https://www.mail-archive.com/haproxy@formilux.org/msg24160.html)

    curl -OJ ftp://ftp.linux.hr/pub/openssl/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    echo ${OPENSSL_SHA256} openssl-${OPENSSL_VERSION}.tar.gz | sha256sum -c && \
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config no-shared --prefix=/tmp/openssl --openssldir=/tmp/openssl && \
    make && \
    make install && \
    cd .. && \

    # HAProxy

    curl -OJL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/devel/haproxy-${HAPROXY_VERSION}.tar.gz" && \
    echo "${HAPROXY_MD5} haproxy-${HAPROXY_VERSION}.tar.gz" | md5sum -c && \
    tar zxvf haproxy-${HAPROXY_VERSION}.tar.gz && \
    make -C haproxy-${HAPROXY_VERSION} \
      TARGET=linux2628 \
      USE_SLZ=1 SLZ_INC=../libslz/src SLZ_LIB=../libslz \
      USE_STATIC_PCRE=1 USE_PCRE_JIT=1 PCREDIR=/tmp/pcre \
      USE_OPENSSL=1 SSL_INC=/tmp/openssl/include SSL_LIB=/tmp/openssl/lib USE_PTHREAD_PSHARED=1 \
      all \
      install-bin && \
    mkdir -p /usr/local/etc/haproxy && \
    cp -R haproxy-${HAPROXY_VERSION}/examples/errorfiles /usr/local/etc/haproxy/errors && \

    # Clean up
    rm -rf /var/lib/apt/lists/* /tmp/* haproxy* pcre* openssl* libslz* && \
    apt-get purge -y --auto-remove ${buildDeps}


CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
