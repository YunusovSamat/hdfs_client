#!/bin/bash

usr="samat"
full_path='/'

send_request () {
  method=$1
  hpath=$2
  op=$3
  response=$(curl -s -X "$method" "http://localhost:50070/webhdfs\
/v1$hpath?user.name=$usr&op=$op")
}


mkdir_func () {
  hpath=$1
  if [[ ${hpath:0:1} == '/' ]]; then
    send_request "PUT" "$hpath" "MKDIRS"
  else
    send_request "PUT" "$full_path$hpath" "MKDIRS"
  fi
  if [[ -z "$response" ]]; then
    echo "$hpath: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".boolean") == "false" ]]; then
    echo "$hpath: Error: folder not created"
  fi
}


ls_func () {
  hpath=$1
  if [[ ${hpath:0:1} == '/' ]]; then
      send_request "GET" "$hpath" "LISTSTATUS"
    else
      send_request "GET" "$full_path$hpath" "LISTSTATUS"
    fi
  result=$(echo "$response" | jq ".RemoteException.message")
  if [[ "$result" != "null" ]]; then
    echo "$result" | tr -d '"'
    exit
  fi
  i=0
  obj=$(echo "$response" | jq ".FileStatuses.FileStatus[$i].pathSuffix")
  echo "$2:"
  while [[  "$obj" != "null" ]]; do
      echo "   $obj" | tr -d '"'
      let "i += 1"
      obj=$(echo "$response" | jq ".FileStatuses.FileStatus[$i].pathSuffix")
  done
}


delete_func () {
  hpath=$1
  if [[ ${hpath:0:1} == '/' ]]; then
    send_request "DELETE" "$hpath" "DELETE"
  else
    send_request "DELETE" "$full_path$hpath" "DELETE"
  fi
  if [[ -z "$response" ]]; then
    echo "$1: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".RemoteException.message") != "null" ]]; then
    echo "$response" | jq ".RemoteException.message" | tr -d '"'
  elif [[ $(echo "$response" | jq ".boolean") == "false" ]]; then
    echo "$1:  Error: folder of file not deleted"
  fi
}


put_append_func () {
  method=$1
  op=$2
  lpath=$3
  hpath=$4
  if [[ ${hpath:0:1} == '/' ]]; then
    send_request "$method" "$hpath" "$op&noredirect=true"
  else
    send_request "$method" "$full_path$hpath" "$op&noredirect=true"
  fi
  if [[ -z "$response" ]]; then
    echo "$hpath: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".RemoteException.message") != "null" ]]; then
    echo "$response" | jq ".RemoteException.message" | tr -d '"'
  elif [[ $(echo "$response" | jq ".Location") != "null" ]]; then
    rp_datanode=$(curl -s -X "$method" -T $lpath $(echo "$response" | jq ".Location" | tr -d '"'))
    if [[ -n "$rp_datanode" ]]; then
      if [[ $(echo "$rp_datanode" | jq ".RemoteException.message") != "null" ]]; then
        echo "$rp_datanode" | jq ".RemoteException.message" | tr -d '"'
      else
        echo "$rp_datanode"
      fi
    fi
  fi
}


get_func () {
  hpath=$1
  lpath=$2
  if [[ ${hpath:0:1} == '/' ]]; then
    send_request "GET" "$hpath" "OPEN&noredirect=true"
  else
    send_request "GET" "$full_path$hpath" "OPEN&noredirect=true"
  fi
  if [[ -z "$response" ]]; then
    echo "$hpath: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".RemoteException.message") != "null" ]]; then
    echo "$response" | jq ".RemoteException.message" | tr -d '"'
  elif [[ $(echo "$response" | jq ".Location") != "null" ]]; then
    rp_datanode=$(curl -s $(echo "$response" | jq ".Location" | tr -d '"'))
    if [[ -n "$rp_datanode" ]]; then
        echo "$rp_datanode" > "$lpath"
    fi
  fi
}


cd_func () {
  hpath=$1
  if [[ ${hpath:0:1} == '/' ]]; then
    send_request "GET" "$hpath" "LISTSTATUS"
  else
    send_request "GET" "$full_path$hpath" "LISTSTATUS"
  fi
  if [[ -z "$response" ]]; then
    echo "$hpath: Error: not the right path"
    exit
  elif [[ $(echo "$response" | jq ".FileStatuses.FileStatus") != "null" ]]; then
    echo "$response" | jq ".FileStatuses.FileStatus"
  fi
}


case $1 in
-mkdir)
  while [[ -n $2 ]]; do
    mkdir_func $2
    shift
  done;;
-ls)
  ls_func $2;;
-cd)
  cd_func $2;;
-delete)
  while [[ -n $2 ]]; do
    delete_func $2
    shift
  done;;
-put)
  put_append_func "PUT" "CREATE" $2 $3;;
-append)
  put_append_func "POST" "APPEND" $2 $3;;
-get)
  get_func $2 $3;;
-*)
  echo "command no found"
esac
