AWS.config access_key_id:     AWS_ACCESS_KEY_ID, 
           secret_access_key: AWS_SECRET_ACCESS_KEY, 
           region:            AWS_REGION,
           user_agent_prefix: "",
           dynamo_db:         { :api_version => '2012-08-10' }

$ddb = AWS::DynamoDB.new
                                 
