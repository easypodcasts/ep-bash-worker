# Easypodcasts worker, Bash version

## Requirements

- ffmpeg
- ffprobe
- jq
- curl

## deploy with docker

```
git clone https://github.com/easypodcasts/ep-bash-worker.git
cd ep-bash-worker
```

Rename the file `env.template` as `.env`, edit it with a provided Easypdcasts worker token and run the service container

```
docker-compose up --build
```
