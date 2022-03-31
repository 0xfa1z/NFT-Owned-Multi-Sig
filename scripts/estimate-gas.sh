#!/usr/bin/env bash

set -eo pipefail

. $(dirname $0)/common.sh

if [[ -z $CONTRACT ]]; then
  if [[ -z ${1} ]];then
    echo '"$CONTRACT" env variable is not set. Set it to the name of the contract you want to estimate gas cost for.'
    exit 1
  else
    CONTRACT=${1}
  fi
fi

estimate_gas $CONTRACT


