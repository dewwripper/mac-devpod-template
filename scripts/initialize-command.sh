#!/bin/bash
set -Eeuo pipefail

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd -P)"
DEVCONTAINER_DIR="$(dirname "${SCRIPTDIR}")"
REPO_PATH="$(dirname "${DEVCONTAINER_DIR}")"
ENV_FILE_PATH="${DEVCONTAINER_DIR}/.env"

REPO_URL="$(git -C "${REPO_PATH}" config --get remote.origin.url 2>/dev/null || true)"
if [[ -n "${REPO_URL}" ]]; then
    REPO_NAME="$(basename -s .git "${REPO_URL}")"
    REPO_PROJECT="$(echo "${REPO_URL}" | awk -F'[:/]' '{print $(NF-1)}' | tr '[:upper:]' '[:lower:]')"
else
    REPO_NAME="$(basename "${REPO_PATH}")"
    REPO_PROJECT="default"
fi
REPO_NAME_SLUG="$(echo "${REPO_NAME}" | tr -d '.')"

error() {
    echo "Error during initialization"
    exit 1
}

trap error ERR

create_directories() {
    echo "Creating directories mounted in docker for persistent data..."
    mkdir -p "${HOME}/.ssh"
    mkdir -p "${HOME}/.local"
    mkdir -p "${HOME}/.gemini"
    mkdir -p "${HOME}/.claude"
    mkdir -p "${HOME}/.gnupg"
    mkdir -p "${HOME}/.config/gh"
    mkdir -p "${HOME}/.tsh"
    mkdir -p "${HOME}/.${REPO_PROJECT}/pre-commit-cache"
    mkdir -p "${HOME}/.${REPO_PROJECT}/commandhistory.d/${REPO_NAME}"
}

create_files() {
    echo "Creating files mounted in docker..."
    touch "${HOME}/.zsh_history"
    touch "${HOME}/.${REPO_PROJECT}/zsh-history"
    touch "${HOME}/.gitconfig"
    touch "${HOME}/.netrc"
    chmod 600 "${HOME}/.netrc"
    if [[ ! -f "${HOME}/.claude.json" ]]; then
        echo "{}" > "${HOME}/.claude.json"
    fi
}

define_docker_args() {
    echo "Defining Docker Args..."
    cat <<EOT > "$ENV_FILE_PATH"
USER=$(whoami)
HOME=${HOME}
REPO_NAME=${REPO_NAME}
PROJECT_DIR=${REPO_PATH}
CONTAINER_USER=$(whoami)
CONTAINER_UID=$(id -u)
CONTAINER_GID=$(id -g)
HOST_IP=host.docker.internal
EOT
}

main() {
    echo "Initialization started..."
    create_directories
    create_files
    define_docker_args
    echo "Initialization completed."
}

main "$@"
