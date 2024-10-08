#!/bin/bash

# vim: filetype=sh

set -euo pipefail
IFS=$'\n\t'

API_TOKEN=$(<~/.hetzner_api)

# ensure we can connect to Hetzner
api_response=$(curl -s -o /dev/null -w "%{response_code}" -H "Authorization: Bearer $API_TOKEN" \
	"https://api.hetzner.cloud/v1/actions")
if [[ $api_response != "200" ]];
then
	echo "Could not connect to Hetzner API. Check key."
	exit 1
fi

# define variables
name=""
location=""
server_type=""
image=""
key=""

# read the arguments
while getopts "n:l:t:i:k:" flag
do 
	case "${flag}" in 
		n) name=${OPTARG};;
		l) location=${OPTARG};;
		t) server_type=${OPTARG};;
		i) image=${OPTARG};;
		k) key=${OPTARG};;
	esac
done

# get a name for the server
if [[ -z "$name" ]]
then
	echo -n "Server name?: "
	read -r name
fi
echo "name: $name"


# get the list of locations
if [[ -z "$location" ]]
then
	loc_json=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
		"https://api.hetzner.cloud/v1/locations")
	locations=( $(echo $loc_json | grep -o '"name": "[^"]*' | grep -o '[^"]*$') )
	# select a location from the list
	echo "location?"
	select location in "${locations[@]}"; do
		case $location in 
			*)
				break;;
		esac
	done
fi
echo "location: $location"

# get the list of server types
if [[ -z "$server_type" ]]
then
	server_json=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
		"https://api.hetzner.cloud/v1/server_types")
	server_types=( $(echo $server_json | grep -o '"name": "[^"]*' | grep -o '[^"]*$') )
	# select a server type from the list
	echo "server type?"
	select server_type in "${server_types[@]}"; do
		case $server_type in 
			*)
				break;;
		esac
	done
fi
echo "server type: $server_type"

# get the list of images 
if [[ -z "$image" ]]
then
	images_json=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
		"https://api.hetzner.cloud/v1/images?type=system")
	images=( $(echo $images_json | grep -o '"name": "[^"]*' | grep -o '[^"]*$') )
	
	# select an image  from the list
	echo "image?"
	select image in "${images[@]}"; do
		case $image in 
			*)
				break;;
		esac
	done
fi
echo "image: $image"

# get the list of ssh keys 
if [[ -z "$key" ]]
then
	keys_json=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
		"https://api.hetzner.cloud/v1/ssh_keys")
	keys=( $(echo $keys_json | grep -o '"name": "[^"]*' | grep -o '[^"]*$') )
	
	# select a key from the list
	echo "ssh key?"
	select key in "${keys[@]}"; do
		case $key in 
			*)
				break;;
		esac
	done
fi
echo "$key"

# show values and confirm server creation
data=$(
cat <<EOF
{
	"name": "$name",
	"server_type": "$server_type",
	"image": "$image",
	"location": "$location",
	"ssh_keys": [
		"$key"
	]
}
EOF
)

echo "$data"
echo -n "Proceed? [y/n]: "
read -n 1 ans

if [[ "$ans" != "y" ]]; then
	exit
fi

# create the server and store the output in a file
echo "\ncreating $name..."
response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
	-H "Content-Type: application/json" \
	-d "$data" \
	"https://api.hetzner.cloud/v1/servers" \
)

destdir="${name}.json"
echo "$destdir"
echo "$response" > "$destdir"

exit
