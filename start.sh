#!/bin/bash

cd /home/ubuntu/afe_chat

source .venv/bin/activate

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

cd api
/home/ubuntu/.local/bin/uv run uvicorn main:app --workers 2