#!/bin/bash

# Takes a key name as an argument
KEY_NAME=$1
KEY_DIR=$2

# Ensure KEY_DIR is not empty and exists
if [ -z "$KEY_DIR" ] || [ ! -d "$KEY_DIR" ]; then
    echo "Error: Invalid key directory: $KEY_DIR" >&2
    exit 1
fi

FULL_KEY_PATH="${KEY_DIR}/${KEY_NAME}"

echo "Processing SSH key at: $FULL_KEY_PATH" >&2

# Check if the key already exists
if [ ! -f "${FULL_KEY_PATH}" ]; then
    # Generate a new SSH key pair
    ssh-keygen -t ed25519 -f "${FULL_KEY_PATH}" -N "" >&2
    echo "SSH key generated: ${FULL_KEY_PATH}" >&2
else
    echo "Using existing SSH key: ${FULL_KEY_PATH}" >&2
fi

# Output the public key content in JSON format
if [ -f "${FULL_KEY_PATH}.pub" ]; then
    PUBLIC_KEY=$(cat "${FULL_KEY_PATH}.pub")
    echo "{\"public_key\": \"${PUBLIC_KEY}\"}"
else
    echo "Error: SSH public key not found at ${FULL_KEY_PATH}.pub" >&2
    exit 1
fi