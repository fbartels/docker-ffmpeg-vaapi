#!/bin/bash

VAAPI_ENABLED=${VAAPI_ENABLED:-false}
FFMPEG_X264="libx264"
FFMPEG_X265="libx265"

if [[ "true" == "${VAAPI_ENABLED}" ]]; then
	VAAPI_DOCKER_ARGS="--privileged -v /dev/dri:/dev/dri"
	VAAPI_FFMPEG_ARGS="-vaapi_device /dev/dri/renderD128 -hwaccel vaapi -hwaccel_output_format vaapi"
	FFMPEG_X264="h264_vaapi"
	FFMPEG_X265="hevc_vaapi"
fi

# Test Files and Their URLs
declare -A TEST_FILES=( 
	["test_HD.mpg"]="https://alcorn.com/wp-content/downloads/test-files/AC3AlcornTest_HD.mpg" 
)

# List of Test to Run
TESTS=${TESTS:-mpeg2-x264 mpeg2-x265 ac3-eac3 ac3-aac}

# Amount of time to spend between checks of running containers
SLEEP_TIME=${SLEEP_TIME:-5}

DIR=$(mktemp -d)
cd ${DIR}

function runTest() {
	local TEST_NAME=$1
	local TEST_FILE=$2
	local FFMPEG_ARGS=$3

	if [[ $TESTS == *"${TEST_NAME}"* ]]; then
		if [[ ! -f ${TEST_FILE} ]]; then
			echo "Downloading ${TEST_FILE}"
			curl -L -o ${TEST_FILE} ${TEST_FILES[${TEST_FILE}]}
		fi
		mkdir ${TEST_NAME}
		cp ${TEST_FILE} ${TEST_NAME}/
		echo "Starting test ${TEST_NAME}"
		docker run -d --name ${TEST_NAME} \
			${VAAPI_DOCKER_ARGS} \
			-v ${DIR}/${TEST_NAME}:/data \
			ffmpeg:build \
			${VAAPI_FFMPEG_ARGS} \
			-i ${TEST_FILE} \
			${FFMPEG_ARGS} \
			-f matroska \
			${TEST_FILE}_${TEST_NAME}.mkv
	fi
}

runTest "mpeg2-x264" "test_HD.mpg" "-map 0:v -c:v ${FFMPEG_X264}"
runTest "mpeg2-x265" "test_HD.mpg" "-map 0:v -c:v ${FFMPEG_X265}"
runTest "ac3-eac3" "test_HD.mpg" "-map 0:a -c:a eac3 -q:a 540"
runTest "ac3-aac" "test_HD.mpg" "-map 0:a -c:a aac -q:a 2"

FINAL_EXIT_CODE=0
REMAINING_TESTS=${TESTS}
while [[ ! -z "${REMAINING_TESTS}" && ${FINAL_EXIT_CODE} -eq 0 ]]
do
	FOR_TESTS=${REMAINING_TESTS}
	REMAINING_TESTS=""
	for test in ${FOR_TESTS}
	do
		DOCKER_INSPECT_OUT=`docker inspect ${test} | jq '.[0]' `
		DOCKER_RUNNING=`echo ${DOCKER_INSPECT_OUT} | jq '.State.Running'`
		DOCKER_EXIT_CODE=`echo ${DOCKER_INSPECT_OUT} | jq '.State.ExitCode'`
		echo "${test} is running (${DOCKER_RUNNING}) and exited ${DOCKER_EXIT_CODE}"
		if [[ "false" == "${DOCKER_RUNNING}" ]]; then
			if [[ ${DOCKER_EXIT_CODE} -gt 0 ]]; then
				echo "Exit code failure: ${DOCKER_EXIT_CODE}"
				docker logs ${test}
				FINAL_EXIT_CODE=${DOCKER_EXIT_CODE}
				break
			fi
		else
			REMAINING_TESTS="${test} ${REMAINING_TESTS}"
		fi
	done
	sleep ${SLEEP_TIME}
done

docker rm -f ${TESTS}
rm -rf ${DIR}

echo "Final exit code: ${FINAL_EXIT_CODE}"
exit ${FINAL_EXIT_CODE}

