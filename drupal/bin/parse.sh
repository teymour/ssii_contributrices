#!/bin/bash

CACHE=$(dirname $0)/../.cache

mkdir -p $CACHE
download() {
        md5=$(echo $1 | md5sum | sed 's/ .*//')
	if ! test -e $CACHE/$md5 ; then
		curl -s $1 > $CACHE/$md5.tmp
		mv $CACHE/$md5.tmp $CACHE/$md5
	fi
	cat $CACHE/$md5
}

download https://www.drupal.org/drupal-services/all/all/France?page=0  | grep '/users' | sed 's|/users.*||' | sed 's|.*contributions"><div><a href="|https://www.drupal.org|' >  boites_francaises.list
download https://www.drupal.org/drupal-services/all/all/France?page=1  | grep '/users' | sed 's|/users.*||' | sed 's|.*contributions"><div><a href="|https://www.drupal.org|' >> boites_francaises.list

echo "Nom SSII,page drupal,nombre d'inscrits sur drupal.org,nombre d'issues résolues dans les 3 derniers mois,nombre de contributions dans un module drupal,nombre de développeurs contribuant à des modules drupal"
cat boites_francaises.list | while read boite ; do 
	download $boite > /tmp/$$.html
	nom=$(cat /tmp/$$.html | grep '<h1' | sed 's/.*<h1[^>]*>//' | sed 's/<.h1>//')
	nb=$(cat /tmp/$$.html | grep '/users"' | sed 's/ p[^ ]*<.a> .*//' | sed 's/.*users">//')
        issues=$(cat /tmp/$$.html | grep 'issues fixed in the past 3 months' | sed 's/.*Credited on //' | sed 's/ issues fixed in.*//')
	userid=$(echo $boite | sed 's/.*node.//' | sed 's/\///')
	commits=0
	devs=0
	echo -n $nom",https://www.drupal.org/node/"$userid","$nb","$issues
	for i in 0 1 2 3 4 ; do
		download $boite"/users?page="$i > /tmp/$$.html
		grep '<h2><a href="' /tmp/$$.html | sed 's|.*<h2><a href="|https://www.drupal.org/|' | sed 's|".*||' | while read userurl ; do 
		contrib=$(download $userurl | grep 'last">Total' | sed 's|.*class="last">Total: ||' | sed 's| commits*<.*||')
		commits=$((commits+contrib))
		if test $commits -gt 0 ; then 
			devs=$((devs+1))
		fi
		echo $commits","$devs > /tmp/$$.txt
		done 
	done
	echo ","$(cat /tmp/$$.txt)

done
rm /tmp/$$.html /tmp/$$.txt
