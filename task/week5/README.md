# 1. Monitoring with CloudWatch and SNS
## 1.1 Created an SNS topic subscribed to my email.
### What Changed:
```aws
aws sns create-topic --name harbourbooks-alerts --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws sns subscribe --topic-arn "arn:aws:sns:us-east-1:972766456394:harbourbooks-alerts" --protocol email --notification-endpoint hassan195@gmail.com
```
### Why:  Using email to recieve alarm message

## 1.2 Created a CloudWatch Alarm on EC2 instance's CPUUilization metric, triggered manually to verify its functionality
### What Changed:
```aws
INSTANCEID=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text)

ALARM_TOPICARN=$(aws sns list-topics --query "Topics[?contains(TopicArn,'harbourbooks')].TopicArn" --output text)

aws cloudwatch put-metric-alarm --alarm-name harbourbooks-highcpu --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 5 --threshold 70 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=$INSTANCEID --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-highcpu" --state-value ALARM --state-reason "Testing CloudWach Alarm notification"

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-highcpu" --state-value OK --state-reason "Testing CloudWach Alarm notification"
```
### Why: Using automated way to identify the instance is under sustained load, this gives early warnning via email so intervention can take before an outage.

<img width="1305" height="513" alt="图片" src="https://github.com/user-attachments/assets/96d891a0-f72f-4e5a-bcda-9cc5133310e7" />


## 1.3 Created a CloudWatch Alarm on EC2 instance's StatusCheckFailed metric, triggered manually to verify its functionality
### What Changed:
```aws
aws cloudwatch put-metric-alarm --alarm-name harbourbooks-statuscheckfailed --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --period 60 --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=InstanceId,Value=$INSTANCEID --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-statuscheckfailed" --state-value ALARM  --state-reason "Testing CloudWach Alarm notification: statuscheckfailed"

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-statuscheckfailed" --state-value OK  --state-reason "Testing CloudWach Alarm notification: statuscheckfailed"
```
### Why: Using automated way to identify the instance is not working normally, this gives early warnning via email so intervention can take before an outage.
<img width="1420" height="624" alt="图片" src="https://github.com/user-attachments/assets/8cb69540-bb43-48c6-8d57-e49c03ac7e1a" />

## 1.4 Created a CloudWatch Alarm on Flask's ERROR log, triggered manually to verify its functionality
### What Changed:
```aws
aws logs create-log-group --log-group-name /harbourbooks/flask-app

aws cloudwatch put-metric-alarm  --alarm-name harbourbooks-flaskerror --metric-name FlaskErrorCount --namespace HarbourBooks  --statistic Sum --period 60 --evaluation-periods 1 --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions $ALARM_TOPICARN --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev

aws cloudwatch set-alarm-state --alarm-name "harbourbooks-flaskerror" --state-value ALARM  --state-reason "Testing CloudWach Alarm notification: Flask Error"
```
### Why: Using automated way to identify the flask service is running with error, this gives early warnning via email so intervention can take before an outage.
<img width="1362" height="609" alt="图片" src="https://github.com/user-attachments/assets/a7de3bc2-7f83-469e-b409-c9fc3b4ea26f" />

# 2. Set up least-privilege security group
### What Changed:
```aws
aws ec2 revoke-security-group-egress --group-id sg-0996b4d0795af8a57 --security-group-rule-ids sgr-0021831bcd0f40bd9

aws ec2 authorize-security-group-egress --group-id sg-0996b4d0795af8a57 --protocol tcp --port 443 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress --group-id sg-0996b4d0795af8a57 --protocol tcp --port 3306 --source-group sg-rds-sg
```
### Why: Scoping egress to only the two flows the application actually needs reduces the blast radius.


# 3. Set up Secrets Manager and IAM role to enforce credential security
### What Changed:
```aws
aws secretsmanager create-secret --name harbour-books/db-password --secret-string '{"username":"admin","password":"db_admin_password"}' --tags Key=Project,Value=harbour-books Key=Owner,Value=Hassan Key=Environment,Value=dev
```
```json
secrets-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:972766456394:secret:harbour-books/db-password-odRJ9"
    }
  ]
}
```
```aws
aws iam create-policy --policy-name harbourbooks-read-secret --policy-document file:file://secrets-policy.json

aws iam create-role  --role-name habourbooks-ec2-role --assume-role-policy-document '{ "Version":"2012-10-17", "Statement": [{ "Effect" : "Allow", "Principal" : {"Service":"ec2.amazonaws.com"}, "Action" : "sts:AssumeRole"}] }'

aws iam attach-role-policy --role-name habourbooks-ec2-role --policy-arn arn:aws:iam::972766456394:policy/harbourbooks-read-secret

aws iam create-instance-profile --instance-profile-name harbourbooks-ec2-profile


aws iam add-role-to-instance-profile --instance-profile-name harbourbooks-ec2-profile --role-name habour
books-ec2-role

aws ec2 associate-iam-instance-profile --iam-instance-profile Name=harbourbooks-ec2-profile --instance-id i-09d27cb99efb52494
```
### Why:Moving credential to Secrets Manager centralizes and audits access, and scoping the IAM role to GetSecretValue on one specific secret ARN follows least privilege practice.

## 4. Shipping the secret info via startup script
```shell
#!/bin/bash
#/opt/harbourbooks/startup.sh

SECRET_JSON=$(aws secretsmanager get-secret-value secret-id harbour-books/db-password query SecretString --output text)
DB_USER=$(echo "$SECRET_JSON" awk -F'"username"*:*"' '{print $2}'| awk -F'"' '{print $1}')
DB_PASS=$(echo "$SECRET_JSON" awk -F'"password"*:*"' '{print $2}'| awk -F'"' '{print $1}')


cat > /opt/harbourbooks/.env <<EOF
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASS}
EOF

chmod 600 /opt/harbourbooks/.env
```
