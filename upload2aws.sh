#!/bin/bash


echo "Before we started, please check your aws configure and install jq"
if ! command -v jq &>/dev/null; then
    echo "jq not installed, please install and run again"
    exit
fi
echo "Please enter the table name: "
read -e table_name

max_items=10
echo "Max Items to be read during scan of local dynamodb is set to $max_items. Since dynamodb batchwrite can accept max 25, its advisable to keep it below 15 for no errors during write"

index=0
start_time="$(date -u +%s)"

if [ ! -d $table_name ]; then
    echo "created folder ${table_name}"
    mkdir $table_name
fi

if [ ! -d $table_name/data ]; then
    echo "created folder ${table_name}/data"
    mkdir $table_name/data
fi
echo "For each scan of local dynaomdb and write to aws you will see a dot(.) on console"
aws dynamodb scan --table-name $table_name --max-items $max_items --output json --endpoint-url http://localhost:8000 >./$table_name/data/$index.json
# echo "created ${index} dataset"
cat ./$table_name/data/$index.json | jq '.Items' | jq -M --argjson sublen '25' 'range(0; length; $sublen) as $i | .[$i:$i+$sublen]' | jq "{\"$table_name\": [.[] | {PutRequest: {Item: .}}]}" >./$table_name/data/$index.upjson
filename=${table_name}/data/$index.upjson
# echo "uploading ${filename}"
# aws dynamodb batch-write-item --request-items file://${filename} >${filename}_unprocessed
nextToken=$(cat ./$table_name/data/$index.json | jq '.NextToken')
# echo $nextToken
echo -n "."
((index += 1))

while [ ! -z "${nextToken}" ] && [ "${nextToken}" != "null" ]; do
    aws dynamodb scan --table-name $table_name --max-items $max_items --starting-token $nextToken --output json --endpoint-url http://localhost:8000 >./$table_name/data/$index.json
    # echo "created ${index} dataset"
    cat ./$table_name/data/$index.json | jq '.Items' | jq -M --argjson sublen '25' 'range(0; length; $sublen) as $i | .[$i:$i+$sublen]' | jq "{\"$table_name\": [.[] | {PutRequest: {Item: .}}]}" >./$table_name/data/$index.upjson
    filename=${table_name}/data/$index.upjson
    # echo "uploading ${filename}"
    # aws dynamodb batch-write-item --request-items file://${filename} >${filename}_unprocessed
    nextToken=$(cat ./$table_name/data/$index.json | jq '.NextToken')
    # echo $nextToken
    echo -n "."
    #echo $(cat ./$table_name/data/$index.json | jq '.Items') > ./$table_name/data/$index.json
    ((index += 1))
done

end_export_time="$(date -u +%s)"
echo "used $(($end_export_time - $start_time)) seconds for uploading data"

echo "Completed"
echo "***************************************************************************************"
