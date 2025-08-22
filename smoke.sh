#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-data}"
RELEASE="${2:-postgresql}"
USER="${3:-app}"
DB="${4:-appdb}"
PASS="${5:-app_password_ChangeMe123}"

HOST="${RELEASE}-postgresql.${NAMESPACE}.svc.cluster.local"
echo "Waiting for ${RELEASE} pods to be Ready in namespace ${NAMESPACE}..."
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l app.kubernetes.io/instance="${RELEASE}" --timeout=300s

echo "Running psql smoke test against ${HOST}..."
kubectl -n "${NAMESPACE}" run psql-smoke --rm -i --tty --restart=Never   --image=bitnami/postgresql:16   --env PGPASSWORD="${PASS}" --command --   psql -h "${HOST}" -U "${USER}" -d "${DB}" -c "INSERT INTO app.healthcheck DEFAULT VALUES; SELECT count(*) AS rows_in_healthcheck FROM app.healthcheck;"
