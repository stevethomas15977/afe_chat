#!/bin/bash

cd /home/ubuntu/afe_chat

source .venv/bin/activate

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

cd /home/ubuntu/afe_chat/api
/home/ubuntu/.local/bin/uv run uvicorn main:app --workers 2 > /var/log/afe_api.log 2>&1
