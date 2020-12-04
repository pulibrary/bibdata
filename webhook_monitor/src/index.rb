require "json"
require "base64"
require "securerandom"
require "aws-sdk-lambda"
require "aws-sdk-secretsmanager"
require 'ddtrace'
require "datadog/lambda"

def retrieve_secret
  client = Aws::SecretsManager::Client.new
  resp = client.get_secret_value(secret_id: "alma/sandbox/webhookSecret")
  JSON.parse(resp.secret_string).fetch("key")
end

def signature(event)
  digest = OpenSSL::Digest.new('sha256')
  body = event["body"].to_json
  secret = retrieve_secret
  hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, secret, body))
  hmac.chomp
end

def validate_signature(event)
  signature(event) == event["signature"]
end

def handler(event:, context:)
  Datadog::Lambda.wrap(event, context) do
    raise "Signature Invalid" unless validate_signature(event)
    Datadog::Lambda.metric(
      'alma.webhook.action',
      1,
      "environment": "production",
      "action": event["body"]["action"]
    )
    return event['body'].to_json
  end
end
