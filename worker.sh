#!/usr/bin/env bash

API_HOST="https://roig.is-a.dev/podcasts"
API_ENDPOINT_NEXT="${API_HOST}/api/next"
API_ENDPOINT_CONVERTED="${API_HOST}/api/converted"
WORKER_TOKEN=""
AUTH="Authorization: Bearer ${WORKER_TOKEN}"
TOOLS="jq ffmpeg"

for tool in ${TOOLS}; do
    type "${tool}" > /dev/null 2>&1 || echo "'${tool}' is missing"
done

get_episode() {
    EPISODE_ID=$(jq -r '.id' <<<"${RESP}")
    echo "Got episode ID ${EPISODE_ID}"
    EPISODE_URL=$(jq -r '.url' <<<"$RESP")
    echo "Got episode URL ${EPISODE_URL}"
}

convert_episode() {
    ffmpeg -y -i "${EPISODE_URL}" \
        -ac 1 -c:a libopus -b:a 24k -vbr on -compression_level 10 \
        -frame_duration 60 -application voip episode.opus
}

upload_episode() {
    curl -H "${AUTH}" -F "id=${EPISODE_ID}" \
        -F "audio=@episode.opus" "${API_ENDPOINT_CONVERTED}"
}

clean() {
    rm episode.opus
}

while :; do
    RESP=$(curl -H "${AUTH}" "${API_ENDPOINT_NEXT}" | jq -r)

    # RESP can be:
    # noop -> No episodes to convert
    # Unauthorized -> Check your token
    # {id: some_number, url: some url} -> Get to work

    echo "Got response ${RESP}"
    if [[ "${RESP}" == "noop" ]]; then
        echo "No episodes to convert"
    elif [[ "${RESP}" == "Unauthorized" ]]; then
        echo "Check your token"
        break
    else
        get_episode && convert_episode && upload_episode && clean
        
    fi
    sleep 10
done

exit 0
