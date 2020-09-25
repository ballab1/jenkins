#!/bin/bash

#
# LOGGING
#
declare -r logfile=${TEST_LOGFILE:-docker-image-test.log}
declare -r clijar='/tmp/jenkins-cli.jar'
declare -r jserver='http://localhost:8080'
declare -r wstop=$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd  )

# Clean up previous test log
rm -f $logfile

function displaylog() {
    test -e $logfile && \
        echo "For more information, please read $PWD/$logfile"
}

function clean_scaffold() {
    rm -f "$clijar"
    docker-compose down &>1 >> "$logfile"
}

function on_exit() {
    clean_scaffold
    displaylog
}
trap on_exit EXIT

#
# HELPER
#
declare -r SERVICE_NAME=builder
declare -r CONTAINER_IMAGE=${DOCKER_REGISTRY:-s2.ubuntu.home:5000/}${CONTAINER_OS:-alpine}/jenkins/${JENKINS_VERSION:-2.138.2}:${CONTAINER_TAG:-latest}

run_in_docker() {
    # Overriding the entrypoint since bash_unit expect /usr/local/bin/run.sh and CBF fails
    docker run --rm --entrypoint '' $CONTAINER_IMAGE $@ | tee -a "$logfile"
    exit ${PIPESTATUS[0]} # capture error of docker command
}

run_docker_compose() {
    local ep=$1; shift
    docker-compose run --entrypoint ${ep} $SERVICE_NAME $@ 2>/dev/null | tee -a "$logfile"
    exit ${PIPESTATUS[0]} # capture the error of docker-compose command
}

inspect_docker() {
    docker inspect $CONTAINER_IMAGE | jq -r "$1"
}

sanitize_docker_string() {
    echo $@ | tr -d '\n' | tr -d '\r'
}

# Bash Unit tries to cat the executable command because it assumes a script
echo_and_grep() {
    echo $1 | grep $2
    exit $?
}

###############################################################################
# SCAFFOLD
###############################################################################

function dockerup() {
    local service=$1
    local logf=$2
    local sleepsec=$3

    # check status and exit if already running
    running=$(docker-compose top 2>/dev/null)
    if [[ $running != "" ]]; then
        return
    fi

    # startup docker and give it some time to get online
    docker-compose up -d jenkins &>1 >> "$logf"
    sleep $sleepsec
}

function get_jenkins_cli() {
    local jserv=$1
    local file_location=$2

    if [[ ! -e $file_location ]]; then
        wget --quiet ${jserv}/jnlpJars/jenkins-cli.jar -O $file_location
    fi
}

###############################################################################
# TESTS
###############################################################################

test_jenkins_user_exists() {
    assert_status_code 0 "run_in_docker id jenkins"
    assert_equals 1000 "$(run_in_docker getent passwd jenkins | cut -d: -f3)"
}

test_jenkins_version() {
    dockerup "jenkins" "$logfile" 120
    get_jenkins_cli "$jserver" "$clijar"
    version=$(java -jar "$clijar" -noKeyAuth -s ${jserver} version)
    assert_equals '2.121.2' "$version"
}

test_plugin_list() {
    # Due to a side loading kafkalogs plugin and potential auto-dependency,
    # we need to examine the list and run a check of the shasum when plugins change.
    local docker_install_plugin_list="$wstop/build/usr/share/jenkins/ref/plugins.txt"
    local docker_install_plugin_deps="$wstop/test/plugin-dependencies.txt"
    local expected_sha=$(cat "$docker_install_plugin_list" "$docker_install_plugin_deps" | sort -fu | sha256sum )

    dockerup "jenkins" "$logfile" 120
    get_jenkins_cli "$jserver" "$clijar"
    plugins_sha=$(java -jar "$clijar" -noKeyAuth -s ${jserver} list-plugins | sed -e 's/([^()]*)//g' | awk '{print $1":"$NF}' | sort -fu | sha256sum )
    assert_equals "$expected_sha" "$plugins_sha"
}
