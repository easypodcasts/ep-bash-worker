#!/usr/bin/env bash

API_HOST="https://roig.is-a.dev/podcasts"
API_ENDPOINT_NEXT="${API_HOST}/api/next"
API_ENDPOINT_CONVERTED="${API_HOST}/api/converted"
API_ENDPOINT_CANCEL="${API_HOST}/api/cancel"
#WORKER_TOKEN=""
AUTH="Authorization: Bearer ${WORKER_TOKEN}"
AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:94.0) Gecko/20100101 Firefox/94.0'
TOOLS="jq ffmpeg ffprobe"

error() {
  echo "$@" 1>&2
  exit 1
}

for tool in ${TOOLS}; do
    type "${tool}" > /dev/null 2>&1 || error "ERROR: '${tool}' is missing"
done

get_episode() {
    EPISODE_ID=$(jq -r '.id' <<<"${RESP}")
    echo "Got episode ID ${EPISODE_ID}"
    EPISODE_URL=$(jq -r '.url' <<<"${RESP}")
    EPISODE_FILE="episode_${EPISODE_ID}.opus"
    echo "Got episode URL ${EPISODE_URL}"
}

get_episode_duration() {
    local duration=$(ffprobe "$1" -user_agent "${AGENT}" -show_entries format=duration -v quiet -of csv="p=0")
    echo ${duration%.*}
}

convert_episode() {
    ffmpeg -user_agent "${AGENT}" -y -i "${EPISODE_URL}" \
        -ac 1 -c:a libopus -b:a 24k \
        -apply_phase_inv 0 \
        -frame_duration 60 -application voip "${EPISODE_FILE}"
}

upload_episode() {
    curl -H "${AUTH}" -F "id=${EPISODE_ID}" \
        -F "audio=@${EPISODE_FILE}" "${API_ENDPOINT_CONVERTED}"
}

cancel_episode() {
    curl -H "${AUTH}" -F "id=${EPISODE_ID}" \
        "${API_ENDPOINT_CANCEL}"
}

clean() {
    rm "${EPISODE_FILE}"
}

while :; do
    RESP=$(curl -s -H "${AUTH}" "${API_ENDPOINT_NEXT}" | jq -r)

    # RESP can be:
    # noop -> No episodes to convert
    # Unauthorized -> Check your token
    # {id: some_number, url: some url} -> Get to work

    echo "Got response ${RESP}"
    if [[ "${RESP}" == "noop" ]]; then
        echo "No episodes to convert"
        sleep 10
        continue
    elif [[ "${RESP}" == "Unauthorized" ]]; then
        echo "Check your token"
        break
    fi

    get_episode || { echo 'get_episode failed'; continue; }
    duration_orig=$(get_episode_duration "${EPISODE_URL}")
    convert_episode || { echo "convert_episode ${EPISODE_ID} failed"; cancel_episode; continue; }
    duration_conv=$(get_episode_duration "${EPISODE_FILE}")
    duration_dif=$((duration_orig-duration_conv))

    if [[ "${duration_dif#-}" -lt 60 ]]; then
        echo "Uploading episode ${EPISODE_ID}"
        upload_episode && clean
    else
        echo "Episode ${EPISODE_ID} duration check failed"
        echo "Before: ${duration_orig}"
        echo "After: ${duration_conv}"
        cancel_episode
    fi
done

exit 0
