#!/bin/sh
# Build the Autoregia image and deploy it as a container.
#
#   ./run.sh            build image + restart container
#   ./run.sh pull       pull latest image from GHCR instead of building
#   ./run.sh logs       follow container logs
#   ./run.sh stop       stop and remove the container
set -eu

IMAGE="ghcr.io/dbremont/autoregia:latest"
CONTAINER="autoregia"

cd "$(dirname "$0")"

# Load repo-local defaults (.env is git-ignored). Real env vars still win.
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

PORT="${AUTOREGIA_PORT:-8080}"

case "${1:-deploy}" in
  stop)
    docker rm -f "$CONTAINER" 2>/dev/null || true
    exit 0
    ;;
  logs)
    exec docker logs -f "$CONTAINER"
    ;;
  pull)
    docker pull "$IMAGE"
    ;;
  deploy|build|"")
    docker build -t "$IMAGE" .
    ;;
  *)
    echo "usage: $0 [deploy|pull|logs|stop]" >&2
    exit 2
    ;;
esac

# Mount the repo's .env into the container if present (CouchDB credentials,
# etc.). Real environment variables still win inside the app.
ENV_MOUNT=""
if [ -f .env ]; then
  ENV_MOUNT="-v ${PWD}/.env:/srv/.env:ro"
fi

docker rm -f "$CONTAINER" 2>/dev/null || true
# shellcheck disable=SC2086
exec docker run -d --name "$CONTAINER" --restart unless-stopped \
  --network host \
  -e AUTOREGIA_PORT="$PORT" \
  $ENV_MOUNT \
  "$IMAGE"
