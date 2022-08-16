## Webhook monitor

Alma can be configured to issue webhooks in response to certain events in the
ILS. This is an AWS lambda function that listens for the webhooks and posts
their contents to a queue. In bibdata proper we poll that queue in order
to create our own events and dumps.

An architecture diagram can be found at https://lib-confluence.princeton.edu/display/ALMA/Systems+Documentation

## Initial setup

These steps don't need to be performed more than once and have already been done
for this webhook.

### Getting to AWS

Use https://princeton.edu/aws to get to the AWS Management Console. You'll be required to log in via CAS.

### Alma Webhook Setup

Construct the URL:

- In [AWS Lambda](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/discover)
  - In the left sidebar click on `Applications`
  - Select "alma-webhook-monitor-production" or 'alma-webhook-monitor-staging' or "alma-webhook-monitor-qa"
  - The `API Endpoint` is the base URL
  - In section 'Resources' click `WebhookReceiver`
  - In section `Function overview` click `API Gateway`. In section `Triggers`, expand `details` in `API Gateway`.
  - Get the `Resource path`
  - The base URL and resource path together form the URL alma needs

Get the secret:

- In AWS Secrets Manager
  - Find (or generate) the secret in AWS Secrets Manager
    - It's called alma/sandbox/webhookSecret
    - Use the "Retrieve secret value" button

Configure the URL and secret in Alma:

- In Alma
  - Go to the admin area (click the gear)
  - Search for Integration Profiles
  - Select Webhook Monitoring
  - In the actions tab there's a place for the secret and the URL
  - Make sure to click "activate"

Here is some alma documentation about webhooks:
https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/090Integrations_with_External_Systems/030Resource_Management/300Webhooks

## Tests

To run the tests for the alma webhook monitor:
* `$ cd webhook_monitor/src`
* `$ bundle exec rspec`

## Webhook Deploy Instructions

When the webhook monitor code is updated, a deploy will be needed. We do this
using AWS deployment tools.

### Deploy setup
* Install the AWS CLI:
[Directions](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-confirm)
* Install the AWS SAM CLI:
[Directions](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-mac.html)
* Set up a `alma-events` AWS profile. You can get the AccessID/AccessKey from
`lpass show --all Shared-ITIMS-Passwords/alma/MarcLiberationAWS`
* Configure the profile via `aws configure --profile alma-events`
  - Set default region to us-east-1
  - Set default output format to json

### Deploy the webhook monitor code

The deploy must be run from within the `webhook_monitor` directory.

* `./deploy.sh [staging/qa/production]`


## If you need to create a new AWS lambda function for a new environment
- Update `./deploy.sh` with the new environment.
- Run: `./deploy.sh <new-env-name>`. This will use `webhook_monitor/template.yml` and create the necessary queues, Getway API and functions in AWS.
- In ansible update the playbook with the new `SQS_QUEUE_URL`. You can get the new value from https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues or from the updated `./deploy.sh` where you set the new `QueueName=`

## Monitoring

Webhooks can be monitored on this [DataDog
dashboard](https://app.datadoghq.com/dashboard/h8i-8uj-25j/alma-webhook-status?from_ts=1588799410114&live=true&to_ts=1588803010114).

### Datadog integration configuration

- Add/configure the AWS stuff to DataDog
  - https://docs.datadoghq.com/integrations/amazon_web_services/?tab=automaticcloudformation
- Add/configure the Datadog forwarder by pushing the "launch stack" button
  - https://docs.datadoghq.com/serverless/forwarder/
  - This sets up a datadog lambda
- Make sure you use the datadog-specific aws layer
- Add a cloudwatch trigger
  - there's a lambda for the datadog forwarder
  - go to cloudwatch logs
  - Add a trigger
    - from cloudwatch logs
    - log group is the name of the lambda
    - give it a name

Then using the datadog libraries in your lambda should all work.

#### Datadog integration: how it works

When you wrap the logic of your lambda in the datadog funciton it adds a log
line to your cloudwatch logs, it doesn't actually send anything to datadog yet.

The Datadog lambda ("forwarder") bundles up your logs and ships them to Datadog.

So the Datadog lambda just needs to know when to run.

When you add a trigger for the cloud watch logs it says "whenever I get a new
log on this lambda fire the datadog lambda".

The datadog lambda then looks at the logs and finds / ships datadog-y ones.

(Your lambda and datadog's lambda use the same cloudwatch.)
