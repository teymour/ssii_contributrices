#!/bin/bash

cd $(dirname $0)/..

curl -s "https://api.github.com/orgs/"$1"/repos" | grep -A 1 'private": ' | grep '"html_url"' | sed 's/.*": "//' | sed 's/".*//' | while read repo; do 
	bash bin/export_a_git.sh $repo
done
