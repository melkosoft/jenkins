#!/usr/bin/env bash

set -e;
function print_usage() {
	(>&2 echo -e "Usage $0 -i  -u -d\n");
	(>&2 echo -e "-i:\tThe unique identifier for the jenkins credential");
	(>&2 echo -e "-u:\tThe AWS IAM username to check the key for");
	(>&2 echo -e "-d:\tMaximum Age (in days) for AWS Key to be rotated");
	(>&2 echo -e "-o:\tOutput file to temporaly store new generated AWS keys");
	exit 1;
}

function process_key() {
	local kuser=$1;
	local kdate=$(date -d $2 +%s);
	local kkey=$3;
	local exp_date=$(date -d "now - $4 days" +%s);
        local output=$5

	if [ $kdate -le $exp_date ]; then
		echo "Credential '$kkey' is expired and will be rotated.";

		# get new key
		local create_call=$(aws iam create-access-key --user-name "$kuser");

		local new_access_key=$(echo $create_call | jq -r '.AccessKey.AccessKeyId');
		local new_secret_key=$(echo $create_call | jq -r '.AccessKey.SecretAccessKey');

		# set old key inactive
		aws iam update-access-key --access-key-id "$kkey" --status Inactive --user-name "$kuser";

		echo "Update jenkins credential with the newly created AccessKey.";
                echo "$credential_id:$kkey:$new_access_key:$new_secret_key" > $output

		# delete old key since this was successful.
		aws iam delete-access-key --access-key-id "$kkey" --user-name "$kuser";

	else
		echo "Credential '$kkey' was not rotated because it is not expired.(Created: $(date -d $2 +%D))";
	fi

}

function roll_back() {
	kusername=$1;
	kaccesskey=$2;

	if [ -z "${kusername}" ] || [ -z "${kaccesskey}" ]; then
		(>&2 echo "FATAL: Missing required values to rollback.");
		exit 1;
	fi

	## Set the original key back to active
	aws iam update-access-key --access-key-id $kaccesskey --status Active --user-name $kusername;

	(>&2 echo "There was a failure and the access key ($kaccesskey) was set back to the Active state.");
	# This will always exit 1 because if we come here we are in a failure state.
	exit 1;
}

function run_rotate() {
        local script_path=$(dirname $(realpath $0))
	while getopts "i:u:d:o:" arg; do
		case $arg in
			i)
				local credential_id=$OPTARG;
			;;
			u)
				local user_account=$OPTARG;
			;;
			d)
				local credential_age=$OPTARG;
			;;
			o)
				local script_output=$OPTARG;
			;;

		esac
	done
	shift $((OPTIND-1))

	if [ -z "${user_account}" ] || [ -z "${credential_id}" ]; then
		print_usage;
	fi
        
        if [ -z "${credential_age}" ]; then
               credential_age=30
        fi


        if [ -z "${script_output}" ]; then
               script_output="_temp.data"
        fi
        script_output="$script_path/$script_output"
	# https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/
	local current_keys=$(aws iam list-access-keys --user-name "${user_account}" | jq -r '.AccessKeyMetadata[] |  "\(.UserName),\(.CreateDate),\(.AccessKeyId)"');

	for key in $current_keys; do
		# split by ',' and store
		IFS=, read xusername xcreatedate xaccesskey <<< $key;
		process_key "$xusername" "$xcreatedate" "$xaccesskey" "$credential_age" "$script_output" || roll_back "$xusername" "$xaccesskey";
	done

	echo "Jenkins / AWS Credential rotated for id:user (${credential_id}:${user_account})";
	exit 0;
}


run_rotate $@;