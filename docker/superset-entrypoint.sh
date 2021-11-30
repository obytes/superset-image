#!/bin/bash

set -eo pipefail

if [ "${#}" -ne 0 ]; then
    exec "${@}"
else
    gunicorn \
        --bind  "0.0.0.0:${SUPERSET_PORT}" \
        --access-logfile '-' \
        --error-logfile '-' \
        --workers 10 \
        --worker-class gevent \
        --threads 20 \
        --timeout ${GUNICORN_TIMEOUT:-60} \
        --limit-request-line 0 \
        --limit-request-field_size 0 \
        "${FLASK_APP}"
fi

"$@"