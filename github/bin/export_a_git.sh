#!/bin/bash

CACHE=$(dirname $0)/../.cache/
mkdir -p $CACHE

github_url=$1

rm -rf /tmp/exportgit
mkdir -p /tmp/exportgit
git clone --bare $github_url /tmp/exportgit

download() {
	md5=$(echo $1 | md5sum | sed 's/ .*//')
	if ! test -e $CACHE/$md5 ; then
		curl -s $1 > $CACHE/$md5.tmp
		mv $CACHE/$md5.tmp $CACHE/$md5
	fi
	cat $CACHE/$md5
}

function moreauthor {
	author=$1
	commit=$2
	mycache=$CACHE"/author_"$(echo $author | md5sum | sed 's/ .*//')
	if ! test -e $mycache; then
		commit_url=$(echo $github_url | sed 's|/github.com/|/api.github.com/repos/|' | sed 's|$|/commits/'$commit'|')
		author_url=$(download $commit_url | grep -A 10 "author" | grep '"url":' | sed 's/.*"url": "//' | sed 's/".*//' | head -n 1)
		author_company=$(download $author_url | grep '"company": "' | sed 's/.*"company": "//' | sed 's/".*//')
		echo $author_url";"$author_company > $mycache
	fi
	if test -s $mycahe ; then
		cat $mycache
	else
		echo 
	fi

}

git --git-dir=/tmp/exportgit log --date=short | grep -A 1 -B 2 '^Author: ' | tr '\n' ';' | sed 's/;;*/;/g' | sed 's/--;/\n/g' | sed 's/commit /Commit: /' | while read contrib ; do
	commitid=$(echo $contrib | sed 's/Commit: *//' | sed 's/;.*//')
	date=$(echo $contrib | sed 's/.*;Date: *//' | sed 's/;.*//')
	author=$(echo $contrib | sed 's/.*;Author: *//' | sed 's/;.*//')
	echo -n $github_url";"$commitid";"$date";"$author";"
	moreauthor "$author" $commitid
done
