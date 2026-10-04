#!/bin/sh
set -eu
cd "$(dirname "$0")/server"
exec node server.js
