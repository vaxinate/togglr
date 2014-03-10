#!/usr/bin/env bash

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ln -s "$SCRIPT_DIRECTORY/togglr" "/usr/local/bin/togglr"
