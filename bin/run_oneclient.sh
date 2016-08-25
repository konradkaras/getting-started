#!/bin/bash
# POSIX

SPACES_DIR="${PWD}/Spaces/"

# Error handling.
# $1 - error string
die() {
  echo "${0##*/}: error: $*" >&2
  exit 1
}

# As the name suggests
usage() {
  echo "Usage: ${0##*/}  [-h] --token <token hash> --provider <provider ip> 

This script starts Oneclient components:

Example usage:
${0##*/} --provider 172.16.0.1 --token '_Us_MYaSD80YgPpcKfVSLP-Mz3TIqmN1q1vb3qFJ'
or
export ONECLIENT_AUTHORIZATION_TOKEN='_Us_MYaSD80YgPpcKfVSLP-Mz3TIqmN1q1vb3qFJ'
${0##*/} --provider 'node1.oneprovider.onedata.example.com'

Options:
  -h, --help         display this help and exit
  -t, --token        authorization token
  -p, --provider     ip or hostname of provider you want to connect to
  -m, --mount-point  a directory where you what docker to mount your spaces
                     WARNING: the content of this directory will be mounted as a root.
  -d, --detach       run container in background and print container name"
  exit 0
}


main() {
  local token
  local provider
  local mount_point
  local compose_up_opts=""

  if [ ! -z "$ONECLIENT_AUTHORIZATION_TOKEN" ]; then
    token=$ONECLIENT_AUTHORIZATION_TOKEN
  fi

  if [ ! -z "$PROVIDER_HOSTNAME" ]; then
    provider=$PROVIDER_HOSTNAME
  fi

  while (( $# )); do
      case $1 in
          -h|-\?|--help)   # Call a "usage" function to display a synopsis, then exit.
              usage
              exit 0
              ;;
          -t | --token)       
              token=$2
              shift
              ;;
          -p | --provider)      
              provider=$2
              shift
              ;;
          -m | --mount-point)       
              mount_point=$2
              shift
              ;;
          -d | --detach)
              compose_up_opts="$compose_up_opts -d"
              ;;
          -?*)
              printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
              exit 1
              ;;
          *)
              die "no option ${flag}"
              ;;
      esac
      shift
  done

  if [ -z "$token" ]; then
    die "no authorization token supplied. See --help option."
  fi

  if [ -z "$mount_point" ]; then    
    echo "No mount point supplied. Using \"./Spaces\" directory."   
    mount_point=$SPACES_DIR   
  fi

  if [ -z "$provider" ]; then
    echo "No provider supplied. Assuming \"localhost\"."
    provider="localhost"
  fi
  
  # Setting up shared mount for Spaces volume
  mkdir "$mount_point"
  sudo mount -o bind "$mount_point" "$mount_point"
  sudo mount --make-shared "$mount_point"

  echo "After you exit the container you need to manually run: sudo umount \"$mount_point\""

  service='oneclient'
  MOUNT_POINT=$mount_point ONECLIENT_AUTHORIZATION_TOKEN=$token PROVIDER_HOSTNAME=$provider docker-compose -f "docker-compose-${service}.yml" up ${compose_up_opts} "oneclient"
  
}

