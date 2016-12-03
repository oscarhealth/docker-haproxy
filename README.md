# aasmith/docker-haproxy
HAProxy compiled against newer/faster libraries (PCRE w/ JIT, SLZ, and OpenSSL 1.1.0).

This haproxy docker image uses statically-linked modern libraries where
possible. Otherwise, it attempts to follow the official docker image as
closely as possible. Substitute the image name where needed, as in the example
below.

## Usage

Example `Dockerfile`:

```Dockerfile
FROM aasmith/haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

To pin to a specific version, use the branch or tag:

```
FROM aasmith/haproxy:1.6 # stay on the latest the 1.6 line
```

```
FROM aasmith/haproxy:1.6.8 # use exactly 1.6.8
```

### Lua

A lua version is also available on the `lua` branch:

```
FROM aasmith/haproxy:lua # latest lua
```

```
FROM aasmith/haproxy:lua-1.6.8
```

The lua version also includes the luarocks package manager.

For more information about using these images, see the offical docker image
instructions at https://github.com/docker-library/docs/tree/master/haproxy#how-to-use-this-image.

## Libraries

### PCRE

Enables PCRE JIT compilation for faster regular expression parsing. The [PCRE
Peformance Project][0] has more information on benchmarks, etc.

Compilation follows as close as possible to the [debian package][1], excluding
C++ support and dynamic linking.

[0]: http://sljit.sourceforge.net/pcre.html
[1]: https://buildd.debian.org/status/fetch.php?pkg=pcre3&arch=i386&ver=2%3A8.35-3.3%2Bdeb8u2&stamp=1452484092

### Stateless Zip (SLZ)

Created by the HAProxy maintainer, SLZ is a stream compressor for producing
gzip-compatible output. It has lower memory usage, no dictionary persistence,
and runs about 3x faster than zlib.

See the [Stateless Zip project][2] for background, benchmarks, etc.

[2]: http://1wt.eu/projects/libslz/

### OpenSSL

Since 1.7, this image compiles against [OpenSSL][3] 1.1.0. Before 1.7,
[LibreSSL][4] was used until a [breaking change][5].

[3]: https://openssl.org
[4]: https://libressl.org
[5]: https://www.mail-archive.com/haproxy@formilux.org/msg24154.html

## Compilation Details

Output from `haproxy -vv`:

```
$ docker run --rm aasmith/haproxy haproxy -vv
HA-Proxy version 1.7.0-e59fcdd 2016/11/25
Copyright 2000-2016 Willy Tarreau <willy@haproxy.org>

Build options :
  TARGET  = linux2628
  CPU     = generic
  CC      = gcc
  CFLAGS  = -O2 -g -fno-strict-aliasing -Wdeclaration-after-statement
  OPTIONS = USE_SLZ=1 USE_OPENSSL=1 USE_STATIC_PCRE=1 USE_PCRE_JIT=1

Default settings :
  maxconn = 2000, bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Encrypted password support via crypt(3): yes
Built with libslz for stateless compression.
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with OpenSSL version : OpenSSL 1.1.0c  10 Nov 2016
Running on OpenSSL version : OpenSSL 1.1.0c  10 Nov 2016
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports prefer-server-ciphers : yes
Built with PCRE version : 8.39 2016-06-14
Running on PCRE version : 8.39 2016-06-14
PCRE library supports JIT : yes
Built without Lua support
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available filters :
	[COMP] compression
	[TRACE] trace
	[SPOE] spoe
```
