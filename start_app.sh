#!/bin/bash

cd /home/ubuntu/afe_chat

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

cd /home/ubuntu/afe_chat/app
npm run dev > /home/ubuntu/afe_chat/app/afe_app.log 2>&1
