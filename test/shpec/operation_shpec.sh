readonly STARTUP_TIME=1
readonly TEST_DIRECTORY="test"

# These should ideally be a static value but hosts might be using this port so 
# need to allow for alternatives.
DOCKER_PORT_MAP_TCP_2015="${DOCKER_PORT_MAP_TCP_2015:-443}"
DOCKER_PORT_MAP_TCP_8080="${DOCKER_PORT_MAP_TCP_8080:-80}"
DOCKER_PORT_MAP_TCP_8443="${DOCKER_PORT_MAP_TCP_8443:-8443}"

function __destroy ()
{
	:
}

function __get_container_port ()
{
	local container="${1:-}"
	local port="${2:-}"
	local value=""

	value="$(
		docker port \
			${container} \
			${port}
	)"
	value=${value##*:}

	printf -- \
		'%s' \
		"${value}"
}

# container - Docker container name.
# counter - Timeout counter in seconds.
# process_pattern - Regular expression pattern used to match running process.
# ready_test - Command used to test if the service is ready.
function __is_container_ready ()
{
	local container="${1:-}"
	local counter=$(
		awk \
			-v seconds="${2:-10}" \
			'BEGIN { print 10 * seconds; }'
	)
	local process_pattern="${3:-}"
	local ready_test="${4:-true}"

	until (( counter == 0 )); do
		sleep 0.1

		if docker top ${container} \
			| grep -qE "${process_pattern}" \
			&& eval "${ready_test}" \
			&> /dev/null
		then
			break
		fi

		(( counter -= 1 ))
	done

	if (( counter == 0 )); then
		return 1
	fi

	return 0
}

function __setup ()
{
	:
}

# Custom shpec matcher
# Match a string with an Extended Regular Expression pattern.
function __shpec_matcher_egrep ()
{
	local pattern="${2:-}"
	local string="${1:-}"

	printf -- \
		'%s' \
		"${string}" \
	| grep -qE -- \
		"${pattern}" \
		-

	assert equal \
		"${?}" \
		0
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

	trap "__terminate_container caddy_1 &> /dev/null; \
		exit 1" \
		INT TERM EXIT

	describe "Basic Caddy operations"
		describe "Named container"
			__terminate_container \
				caddy_1 \
			&> /dev/null

			it "Can run."
				docker run -d \
					--name caddy_1 \
					--publish ${DOCKER_PORT_MAP_TCP_2015}:2015 \
					--publish ${DOCKER_PORT_MAP_TCP_8080}:8080 \
					jdeathe/caddy:latest \
				&> /dev/null

				if ! __is_container_ready \
					caddy_1 \
					${STARTUP_TIME} \
					"/usr/sbin/caddy "
				then
					exit 1
				fi

				container_running_id="$(
					docker ps \
						-aq \
						--filter name=caddy_1 \
						--filter status=running
				)"

				assert __shpec_matcher_egrep \
					"${container_running_id}" \
					"^[0-9a-zA-Z]{12}"
			end

			it "Can publish ${DOCKER_PORT_MAP_TCP_8080}:8080."
				container_port_8080="$(
					__get_container_port \
						caddy_1 \
						8080/tcp
				)"

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

			it "Can publish ${DOCKER_PORT_MAP_TCP_2015}:2015."
				container_port_2015="$(
					__get_container_port \
						caddy_1 \
						2015/tcp
				)"

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
		end

		describe "Unencrypted requests"
			it "Responds with code 301."
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
		end

		describe "Encrypted requests"
			it "Responds with code 200."
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
	__destroy
end
