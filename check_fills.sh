#!/bin/bash
echo "=== Today Fills Check $(date) ==="
LATEST=$(ssh Data_colo@192.168.71.200 "ls -t /data/logs/Strategy-*_algo_1_*.log | head -1")
echo "Log: $LATEST"
echo "---"
ssh Data_colo@192.168.71.200 "grep FTRD $LATEST" | awk -F'FTRD:' '{print $2}' | awk -F',' '{
  bs=($3==1?"BUY":"SELL")
  printf "Token=%-6s | %-4s | qty=%-5s | price=%s | time=%s\n", $10, bs, $8, $9, $11
}'
echo "=== Done ==="
