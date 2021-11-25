#!/usr/bin/env bash

AUTH="Authorization: Bearer $WORKER_TOKEN"

while :; do
    RESP=$(curl -H "$AUTH" $API_ENDPOINT_NEXT | jq -r)

    # RESP can be:
    # noop -> no episodes to convert
    # Unauthorized -> fix your token
    # {id: some_number, url: some url} -> get to work

    echo "got response $RESP"
    if [ "$RESP" = "noop" ]; then
        echo "nothing to do"
    elif [ "$RESP" = "Unauthorized" ]; then
        echo "token is wrong"
        break
    else
        EPISODE_ID=$(jq -r '.id' <<<$EPISODE)
        echo "got episode id $EPISODE_ID"
        EPISODE_URL=$(jq -r '.url' <<<$EPISODE)
        echo "got episode url $EPISODE_URL"
        ffmpeg -y -i "$EPISODE_URL" -ac 1 -c:a libopus -b:a 24k -vbr on -compression_level 10 -frame_duration 60 -application voip episode.opus
        curl -H "$AUTH" -F "id=$EPISODE_ID" -F "audio=@episode.opus" $API_ENDPOINT_CONVERTED
        rm episode.opus
    fi
    sleep 1
done
