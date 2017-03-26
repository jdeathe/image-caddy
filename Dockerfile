# =============================================================================
# jdeathe/caddy
#
# Caddy is an alternative web server that is easy to configure and use.
# =============================================================================
FROM scratch

MAINTAINER James Deathe <james.deathe@gmail.com>

COPY src /

EXPOSE 2015 8080 8443

# -----------------------------------------------------------------------------
# Set default environment variables used to configure the service container
# -----------------------------------------------------------------------------
ENV CADDY_VERSION="0.9.5" \
	CADDYPATH="/var/caddy" \
	CASE_SENSITIVE_PATH=true

# -----------------------------------------------------------------------------
# Set image metadata
# -----------------------------------------------------------------------------
ARG RELEASE_VERSION="1.0.0"
LABEL \
	install="\
docker run -d \ 
--name \${NAME} \
--restart always \
--publish 80:8080 \
--publish 443:2015 \
jdeathe/caddy:${RELEASE_VERSION}" \
	uninstall="\
if [[ -n $(docker ps -aq --filter \"name=\${NAME}\") ]]; then \
  printf -- \"---> Terminating container\n\"; \
  docker stop \${NAME} > /dev/null 2>&1; \
  if docker rm -f \${NAME} &> /dev/null; then \
    printf -- \" \033[1;32m--->\033[0m Container terminated\n\"; \
  else \
    printf -- \" \033[1;31m--->\033[0m Container termination failed\n\"; \
  fi; \
else \
  printf -- \"---> Container termination skipped\n\"; \
fi;" \
	org.deathe.name="caddy" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/caddy:${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/image-caddy" \
	org.deathe.description="Caddy - The HTTP/2 web server with automatic HTTPS." \
	org.deathe.caddy.version="${CADDY_VERSION}" \
	org.deathe.caddy.url="https://caddyserver.com" \
	org.deathe.caddy.features="awslambda,cors,expires,filter,ipfilter,jwt,minify"

USER 497:497

WORKDIR /var/www/app

ENTRYPOINT ["/usr/sbin/caddy"]

CMD ["-conf", "/etc/caddy/Caddyfile", "-quiet=true"]