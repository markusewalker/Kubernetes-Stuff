#!/usr/bin/expect -f

spawn "basic-k8s-commands.sh"

expect "Please select an option below:\r"
send "1\r"

expect "Do you want to continue? Enter 'yes' or 'no':\r"
send "no\r"

expect eof