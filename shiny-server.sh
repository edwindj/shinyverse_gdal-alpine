#!/bin/sh

# Make sure the directory for individual app logs exists
# Moved these instructions to Dockerfile for now:
# mkdir -p /var/log/shiny-server
# chown shiny:shiny /var/log/shiny-server

exec node /usr/local/shiny-server/lib/main.js 2>&1
