#!/bin/sh

run() {
  if ! pgrep -f "$1" ;
  then
    "$@"&
  fi
}

run xmodmap-watcher
run autorandr-watcher
run emacs
run firefox
run discord --start-minimized
run Telegram -startintray
