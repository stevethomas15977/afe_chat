#!/bin/bash

cd /home/ubuntu/afe_chat

source .venv/bin/activate

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

cd /home/ubuntu/afe_chat/api
/home/ubuntu/.local/bin/uv run uvicorn main:app --workers 2 --host 0.0.0.0 --port 8000

cd /home/ubuntu/afe_chat/app
npm run dev