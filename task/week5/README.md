# 1. Monitoring with CloudWatch and SNS
## 1.1 Created an SNS topic subscribed to my email.
### What Changed:
```aws
aws sns create-topic --name harbourbooks-alerts --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws sns subscribe --topic-arn "arn:aws:sns:us-east-1:xxxxxxxxxx:harbourbooks-alerts" --protocol email --notification-endpoint xxxxxxx@gmail.com

```
### Why:  Using email to recieve alarm message

## 1.2 Created a CloudWatch Alarm on EC2 instance's CPUUilization metric, triggered manually to verify its functionality
### What Changed:
```aws
INSTANCEID=$(aws ec2 describe-instances filters "Name=tag:Project, Values=harbour-books" --query "Reservations[*].Instances[*].InstanceId" --output text)

ALARM_TOPICARN=$(aws sns list-topics --query "Topics[?contains(TopicArn,'harbourbooks')].TopicArn" --output text)

aws cloudwatch put-metric-alarm --alarm-name harbourbooks-highcpu --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 5 --threshold 70 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=$INSTANCEID --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-highcpu" --state-value ALARM --state-reason "Testing CloudWach Alarm notification"

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-highcpu" --state-value OK --state-reason "Testing CloudWach Alarm notification"
```
### Why: Using automated way to identify the instance is under sustained load, this gives early warnning via email so intervention can take before an outage.

## 1.3 Created a CloudWatch Alarm on EC2 instance's StatusCheckFailed metric, triggered manually to verify its functionality
### What Changed:
```aws
aws cloudwatch put-metric-alarm --alarm-name harbourbooks-statuscheckfailed --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --period 60 --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=$INSTANCEID --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-statuscheckfailed" --state-value ALARM  --state-reason "Testing CloudWach Alarm notification: statuscheckfailed"

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-statuscheckfailed" --state-value OK  --state-reason "Testing CloudWach Alarm notification: statuscheckfailed"
```
### Why: Using automated way to identify the instance is not working normally, this gives early warnning via email so intervention can take before an outage.

## 1.4 Created a CloudWatch Alarm on Flask's ERROR log, triggered manually to verify its functionality
### What Changed:
```aws
aws logs create-log-group --log-group-name /harbourbooks/flask-app

aws logs put-metric-filter --log-group-name /harbourbooks/flask-app --filter-name flask-error-filter --filter-pattern "ERROR" --metric-transformations metricName=FlaskErrorCount,metricNamespace=HarbourBooks,metricValue=1,defaultValue=0

aws logs put-metric-filter --log-group-name /harbourbooks/flask-app --filter-name flask-error-filter --filter-pattern "ERROR" --metric-transformations metricName=FlaskErrorCount,metricNamespace=HarbourBooks,metricValue=1,defaultValue=0

aws cloudwatch put-metric-alarm  --alarm-name harbourbooks-flaskerror --metric-name FlaskErrorCount --namespace HarbourBooks  --statistic Sum --period 60 --evaluation-periods 1 --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-flaskerror" --state-value ALARM  --state-reason "Testing CloudWach Alarm notification: Flask Error"
```
### Why: Using automated way to identify the flask service is running with error, this gives early warnning via email so intervention can take before an outage.

# 2. Set up least-privilege security group
### What Changed:
```aws
aws ec2 revoke-security-group-egress --group-id sg-0996b4d0795af8a57 --security-group-rule-ids sgr-0021831bcd0f40bd9

aws ec2 authorize-security-group-egress --group-id sg-0996b4d0795af8a57 --protocol tcp --port 443 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress --group-id sg-0996b4d0795af8a57 --protocol tcp --port 3306 --source-group sg-xxxxxxxxxxxxxxxx
```
### Why: Scoping egress to only the two flows the application actually needs reduces the blast radius.


# 3. Set up Secrets Manager and IAM role to enforce credential security
### What Changed:
```aws
PASSWORD=$(aws secretsmanager get-random-password --password-length 32 --exclude-punctuation --query 'RandomPassword' --output text)

aws secretsmanager create-secret --name harbour-books/db-password --secret-string "$(jq -n --arg username "admin" --arg password "$PASSWORD" '{username: $username, password: $password}')" --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev
```
```json
secrets-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:xxxxxxxxxx:secret:harbour-books/db-password-odRJ9"
    }
  ]
}
```
```aws
aws iam create-policy --policy-name harbourbooks-read-secret --policy-document file://secrets-policy.json

aws iam create-role  --role-name harbourbooks-ec2-role --assume-role-policy-document '{ "Version":"2012-10-17", "Statement": [{ "Effect" : "Allow", "Principal" : {"Service":"ec2.amazonaws.com"}, "Action" : "sts:AssumeRole"}] }'

aws iam attach-role-policy --role-name harbourbooks-ec2-role --policy-arn arn:aws:iam::xxxxxxxxxx:policy/harbourbooks-read-secret

aws iam create-instance-profile --instance-profile-name harbourbooks-ec2-profile

aws iam add-role-to-instance-profile --instance-profile-name harbourbooks-ec2-profile --role-name harbourbooks-ec2-role

aws ec2 associate-iam-instance-profile --iam-instance-profile Name=harbourbooks-ec2-profile --instance-id i-09d27cb99efb52494
```
### Why:Moving credential to Secrets Manager centralizes and audits access, and scoping the IAM role to GetSecretValue on one specific secret ARN follows least privilege practice.

## 4. Shipping the secret info via boto3 module
```python
import boto3, json

def get_db_credentials():
    client = boto3.client("secretsmanager", region_name="us-east-1")
    response = client.get_secret_value(SecretId="harbour-books/db-password")
    return json.loads(response["SecretString"])

creds = get_db_credentials()
DB_USER = creds["username"]
DB_PASSWORD = creds["password"]
```