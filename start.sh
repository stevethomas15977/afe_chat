#!/bin/bash

cd /home/ubuntu/afe_chat

source .venv/bin/activate

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

/home/ubuntu/afe_chat/.local/bin/uv uvicorn main:app --workers 2