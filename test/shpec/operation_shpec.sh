readonly BOOTSTRAP_BACKOFF_TIME=1
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_2015="${DOCKER_PORT_MAP_TCP_2015:-443}"
DOCKER_PORT_MAP_TCP_8080="${DOCKER_PORT_MAP_TCP_8080:-80}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-8443}"

function __setup ()
{
	:
}

function __terminate_container ()
{
	local CONTAINER="${1}"

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=paused" &> /dev/null; then
		docker unpause ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=running" &> /dev/null; then
		docker stop ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" &> /dev/null; then
		docker rm -vf ${CONTAINER} &> /dev/null
	fi
}

function test_basic_operations ()
{
	local container_port_8080=""
	local container_port_2015=""
	local container_running_id=""
	local curl_response=""

	trap "__terminate_container caddy_1 &> /dev/null; exit 1" \
		INT TERM EXIT

	describe "Basic Caddy operations"
		__terminate_container \
			caddy_1 \
		&> /dev/null

		it "Runs a Caddy container named caddy_1."
			docker run -d \
				--name caddy_1 \
				--publish ${DOCKER_PORT_MAP_TCP_2015}:2015 \
				--publish ${DOCKER_PORT_MAP_TCP_8080}:8080 \
				jdeathe/caddy:latest \
			&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			container_running_id="$(
				docker ps \
					-aq \
					--filter name=caddy_1 \
					--filter status=running
			)"

			assert unequal \
				"${container_running_id}" \
				""

			it "Runs with the published port ${DOCKER_PORT_MAP_TCP_8080}->8080."
				container_port_8080="$(
					docker port \
						caddy_1 \
						8080/tcp
				)"
				container_port_8080=${container_port_8080##*:}

				if [[ ${DOCKER_PORT_MAP_TCP_8080} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_8080} ]]; then
					assert gt \
						"${container_port_8080}" \
						"30000"
				else
					assert equal \
						"${container_port_8080}" \
						"${DOCKER_PORT_MAP_TCP_8080}"
				fi
			end

			it "Runs with the published port ${DOCKER_PORT_MAP_TCP_2015}->2015."
				container_port_2015="$(
					docker port \
						caddy_1 \
						2015/tcp
				)"
				container_port_2015=${container_port_2015##*:}

				if [[ ${DOCKER_PORT_MAP_TCP_2015} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_2015} ]]; then
					assert gt \
						"${container_port_2015}" \
						"30000"
				else
					assert equal \
						"${container_port_2015}" \
						"${DOCKER_PORT_MAP_TCP_2015}"
				fi
			end

			it "Redirects unencrypted requests with a 301 response."
				curl_response="$(
					curl -ks \
						-o /dev/null \
						-w "%{http_code}:%{redirect_url}" \
						-H "Host: localhost.localdomain" \
						http://127.0.0.1:${container_port_8080}
				)"

				assert equal \
					"${curl_response}" \
					"301:https://localhost.localdomain/"
			end

			it "Accepts encrypted requests with a 200 response."
				curl_response="$(
					curl -ks \
						-o /dev/null \
						-w "%{http_code}" \
						-H "Host: localhost.localdomain" \
						https://127.0.0.1:${container_port_2015}
				)"

				assert equal \
					"${curl_response}" \
					"200"
			end
		end

		__terminate_container \
			caddy_1 \
		&> /dev/null
	end

	trap - \
		INT TERM EXIT
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/caddy:latest"
	__setup
	test_basic_operations
end
