
# Common parameters of create and run targets
define DOCKER_CONTAINER_PARAMETERS
--name $(DOCKER_NAME) \
--restart $(DOCKER_RESTART_POLICY) \
--env "CADDYPATH=$(CADDYPATH)" \
--env "CASE_SENSITIVE_PATH=$(CASE_SENSITIVE_PATH)"
endef

DOCKER_PUBLISH := $(shell \
	if [[ $(DOCKER_PORT_MAP_TCP_2015) != NULL ]]; then printf -- '--publish %s:2015\n' $(DOCKER_PORT_MAP_TCP_2015); fi; \
	if [[ $(DOCKER_PORT_MAP_TCP_8080) != NULL ]]; then printf -- '--publish %s:8080\n' $(DOCKER_PORT_MAP_TCP_8080); fi; \
	if [[ $(DOCKER_PORT_MAP_TCP_8443) != NULL ]]; then printf -- '--publish %s:8443\n' $(DOCKER_PORT_MAP_TCP_8443); fi; \
)
