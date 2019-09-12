#!/bin/bash

for mirror in ~/webhook-mailer/mirrors/*/*/*; do
  if [ ! -d "${mirror}" ]; then
    continue
  fi
  if [ ! -f "${mirror}/config" ]; then
    continue
  fi
  (cd "${mirror}" && pwd && git gc && git prune)
done
