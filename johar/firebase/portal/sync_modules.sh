#!/bin/sh
# Copies the app's training content so the portal can show question text.
# Run before every `firebase deploy --only hosting`.
cd "$(dirname "$0")" && mkdir -p modules && cp ../../assets/modules/*.json modules/ && echo "Copied:" && ls modules
