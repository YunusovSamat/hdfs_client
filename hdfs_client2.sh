#!/bin/bash

send_request () {
 response=$(curl -s -X "$1" "http://localhost:50070/webhdfs/v1$2?user.name=$usr&op=$3")
}

usr="samat"
full_path='/'
cmd=$1
path1=$2
#path2=$3

case $cmd in
-mkdir)
  while [[ -n $2 ]]; do
    send_request "PUT" "$2" "MKDIRS"
    if [[ -z "$response" ]]; then
        echo "$2: Error: not the right path"
        exit
    elif [[ $(echo "$response" | jq ".boolean") == "false" ]]; then
      echo "$2: Error: folder not created"
    fi
    shift
  done;;
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
-cd);;
-delete)
  while [[ -n $2 ]]; do
    send_request "DELETE" "$2" "DELETE"
    if [[ -z "$response" ]]; then
        echo "$2: Error: not the right path"
        exit
    elif [[ $(echo "$response" | jq ".RemoteException.message") != "null" ]]; then
      echo "$response" | jq ".RemoteException.message" | tr -d '"'
    elif [[ $(echo "$response" | jq ".boolean") == "false" ]]; then
      echo "$2:  Error: folder of file not deleted"
    fi
    shift
  done;;
-put)
  send_request "PUT" "$3" "CREATE&noredirect=true"
#  echo "$response"
  if [[ -z "$response" ]]; then
    echo "$2: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".RemoteException.message") != "null" ]]; then
    echo "$response" | jq ".RemoteException.message" | tr -d '"'
  elif [[ $(echo "$response" | jq ".Location") != "null" ]]; then
    rp_datanode=$(curl -s -X PUT -T $2 $(echo "$response" | jq ".Location" | tr -d '"'))
    if [[ -n "$rp_datanode" ]]; then
      if [[ $(echo "$rp_datanode" | jq ".RemoteException.message") != "null" ]]; then
        echo "$rp_datanode" | jq ".RemoteException.message" | tr -d '"'
      else
        echo "$rp_datanode"
      fi
    fi
  fi
  ;;
-*)
  echo "command not found"
esac
