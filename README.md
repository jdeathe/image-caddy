# caddy

[Caddy](http://caddyserver.com/) - The HTTP/2 web server with automatic HTTPS.

## Overview & links

### Tags and respective `Dockerfile` links

- `1.1.0` [(master/Dockerfile)](https://github.com/jdeathe/image-caddy/blob/master/Dockerfile)

## Quick Example

```
$ docker run -d \
  --name caddy_1 \
  --restart always \
  --publish 443:2015 \
  --publish 80:8080 \
  jdeathe/caddy:1.1.0
```

Now point your browser to `http://{docker-host}` where `{docker-host}` is the host name of your docker server and, if all went well, you should be redirected to the `https://{docker-host}` and, after accepting the warning about the automatically generated self-signed TLS/SSL certificate, see the "Hello, world!" page.
