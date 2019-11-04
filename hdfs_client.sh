#!/bin/bash

send_request () {
 response=$(curl -s -X "$1" "http://localhost:50070/webhdfs/v1$2?user.name=$usr&op=$3")
}
usr="samat"

cmd=$1
path1=$2
path2=$3

case $cmd in
-mkdir)
  send_request "PUT" "$path1" "MKDIRS"
  if [[ -z "$response" ]]; then
      echo "Error: not the right path"
      exit
  elif [[ $(echo "$response" | jq ".boolean") == "false" ]]; then
    echo "Error: folder not created"
  fi;;
-ls)
  send_request "GET" "$path1" "LISTSTATUS"
  result=$(echo "$response" | jq ".RemoteException.message")
  if [[ $result != "null" ]]; then
    echo "$result" | tr -d '"'
    exit
  fi
  i=0
  obj=$(echo "$response" | jq ".FileStatuses.FileStatus[$i].pathSuffix")
  echo "$path1:"
  while [[  $obj != "null" ]]; do
      echo "   $obj" | tr -d '"'
      let "i += 1"
      obj=$(echo "$response" | jq ".FileStatuses.FileStatus[$i].pathSuffix")
  done;;
-*)
  echo "command not found"
esac