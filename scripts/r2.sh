# Sourced by the other scripts. Defines s3(): the aws CLI pointed at R2.
# Errors go to aws.err, never to the console, because Actions logs on a public repo are public.
: "${BUCKET:?}" "${JOB:?}" "${R2_ACCOUNT_ID:?}" "${AWS_ACCESS_KEY_ID:?}" "${AWS_SECRET_ACCESS_KEY:?}"
export AWS_DEFAULT_REGION=auto
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
PREFIX="s3://${BUCKET}/jobs/${JOB}"
s3() { aws s3 "$@" --endpoint-url "$R2_ENDPOINT" --only-show-errors 2>>aws.err; }
