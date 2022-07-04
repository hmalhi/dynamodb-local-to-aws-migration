# dynamodb-local-to-aws-migration
Unix script to upload data from local dynamodb tables to aws

Note:
Before migrating do the following:
1. Install jq on the machine where you are running the local dynamodb and will be migrating from
2. Make sure you are able to access local dynamodb on port 8000, if different port please update the script
3. Setup your aws dyanmodb tables and indexes in give region and configure aws cli

Steps to migrate
1. Clone the repo
2. Make sure jq is installed and local dynamodb is running
3. AWS dynamodb tables have been created with indexs. Use aws cli lis-tables, describe-table command to get that information from local dynamodb
e.g aws dynamodb list-tables --endpoint-url http://localhost:8000
aws dynamodb describe-table --table-name StudentSignInOut --endpoint-url http://localhost:8000
4. The default scan record size is 10, which is optimal for any size table increasing it may cause unprocessed records during upload. Change at your own risk.
5. run upload2aws.sh
