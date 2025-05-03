#!/usr/bin/env nu
let modpack_path = (just build-mrpack | complete | get stdout | str trim | ls -f $in | get name | first)

let hosts = [ "deck@deck:/home/deck/Downloads/" "jq@node:/home/jq/Downloads/" ]

$hosts | each { 
		rsync $modpack_path $in | complete | get stderr 
	} | if ($in | is-empty) {null} else {
		$in | wrap error | merge ( $hosts | wrap target ) | move target --before error  
		}
