#!/bin/bash

export PATH='$PATH:/usr/local/bin:/bin:/usr/bin'

base=$(dirname "$0")

exec coffee "$base/github_leaderboard/leaderboard.coffee"
