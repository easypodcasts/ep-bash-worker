#!/usr/bin/env bash

while :; do
    EPISODE=$(curl $API_ENDPOINT_NEXT | jq -r)
    echo "got episode $EPISODE"
    if [ "$EPISODE" = "noop" ]; then
        echo "Nothing to do"
    else
        EPISODE_ID=$(jq -r '.id' <<<$EPISODE)
        echo "got episode id $EPISODE_ID"
        EPISODE_URL=$(jq -r '.url' <<<$EPISODE)
        echo "got episode url $EPISODE_URL"
        ffmpeg -y -i "$EPISODE_URL" -ac 1 -c:a libopus -b:a 24k -vbr on -compression_level 10 -frame_duration 60 -application voip episode.opus
        curl -F "id=$EPISODE_ID" -F "audio=@episode.opus" $API_ENDPOINT_CONVERTED
        rm episode.opus
    fi
    sleep 10
done
