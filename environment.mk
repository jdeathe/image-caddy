# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DOCKER_USER := jdeathe
DOCKER_IMAGE_NAME := caddy
SHPEC_ROOT := test/shpec

# Tag validation patterns
DOCKER_IMAGE_TAG_PATTERN := ^(latest|(1\.[0-9]+\.[0-9]+))$
DOCKER_IMAGE_RELEASE_TAG_PATTERN := ^1\.[0-9]+\.[0-9]+$

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# Docker image/container settings
DOCKER_CONTAINER_OPTS ?=
DOCKER_IMAGE_TAG ?= latest
DOCKER_NAME ?= caddy_1
DOCKER_PORT_MAP_TCP_2015 ?= 443
DOCKER_PORT_MAP_TCP_8080 ?= 80
DOCKER_PORT_MAP_TCP_8443 ?= NULL
DOCKER_RESTART_POLICY ?= always

# Docker build --no-cache parameter
NO_CACHE ?= false

# Directory path for release packages
DIST_PATH ?= ./dist

# ------------------------------------------------------------------------------
# Application container configuration
# ------------------------------------------------------------------------------
CADDYPATH ?= /var/caddy
CASE_SENSITIVE_PATH ?= true