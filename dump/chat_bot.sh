#!/bin/bash

ask_api(){
  PROMPT=${1:-What is Red Hat}
  ENDPOINT='https://test-llama2-autoscale-runai-llm-training1.apps.cluster1.sandbox284.opentlc.com/api/chat'
    curl "${ENDPOINT}" \
    -H 'Content-Type: application/json' \
    -d $'{"model":{"id":"NousResearch/Llama-2-7b-chat-hf","name":"NousResearch/Llama-2-7b-chat-hf","maxLength":4096,"tokenLimit":2048},"messages":[{"role":"user","content":"'"${PROMPT}"'"}]}'
}
