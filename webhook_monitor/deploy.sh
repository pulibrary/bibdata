#!/usr/bin/env bash
if [ $1 == "production" ]
then
  sam deploy --stack-name=alma-webhook-monitor-production \
  --s3-prefix=alma-webhook-monitor \
  --parameter-overrides='StageName="production", QueueName="AlmaBibExportProduction.fifo", SecretID="alma/production/webhookSecret"' \
  --s3-bucket=aws-sam-cli-managed-default-samclisourcebucket-1j1ve93v4jqs9 \
  --region='us-east-1' \
  --capabilities='CAPABILITY_IAM' \
  --profile='alma-events'
elif [ $1 == "staging" ]
then
  sam deploy --stack-name=alma-webhook-monitor-staging \
  --s3-prefix=alma-webhook-monitor \
  --parameter-overrides='StageName="staging", QueueName="AlmaBibExportStaging.fifo", SecretID="alma/sandbox/webhookSecret"' \
  --s3-bucket=aws-sam-cli-managed-default-samclisourcebucket-1j1ve93v4jqs9 \
  --region='us-east-1' \
  --capabilities='CAPABILITY_IAM' \
  --profile='alma-events'
else
  echo 'Please enter either production or staging as the environment'
fi
