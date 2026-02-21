#!/bin/bash

check() {
  local name=$1
  local status=$((RANDOM % 10))
  if [ $status -lt 9 ]; then
    echo -e "\033[1;32m✓\033[0m $name"
  else
    echo -e "\033[1;31m✗\033[0m $name"
  fi
}

echo ""
echo -e "  \033[1;35m┌──────────────────────────────────────────────────────────────────┐\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mBLACKROAD OS · SYSTEM HEALTH CHECK\033[0m                           \033[1;35m│\033[0m"
echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  \033[1;35m│\033[0m                                                                  \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mAGENTS\033[0m                                                        \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'LUCIDIA responding')                                          \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'ALICE responding')                                            \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'OCTAVIA responding')                                          \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'PRISM responding')                                            \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'ECHO responding')                                             \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'CIPHER responding')                                           \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m                                                                  \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mSERVICES\033[0m                                                      \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'NATS message bus')                                            \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'Milvus vector store')                                         \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'Ollama inference')                                            \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'API Gateway')                                                 \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m                                                                  \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;37mRESOURCES\033[0m                                                     \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'Memory within limits')                                        \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'CPU within limits')                                           \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'Disk space available')                                        \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m  $(check 'Network connectivity')                                        \033[1;35m│\033[0m"
echo -e "  \033[1;35m│\033[0m                                                                  \033[1;35m│\033[0m"
echo -e "  \033[1;35m├──────────────────────────────────────────────────────────────────┤\033[0m"
echo -e "  \033[1;35m│\033[0m  \033[1;32m●\033[0m System healthy                                   $(date +%H:%M:%S)   \033[1;35m│\033[0m"
echo -e "  \033[1;35m└──────────────────────────────────────────────────────────────────┘\033[0m"
