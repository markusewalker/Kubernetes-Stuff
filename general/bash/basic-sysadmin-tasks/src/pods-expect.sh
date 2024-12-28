#!/usr/bin/expect -f

spawn "basic-k8s-commands.sh"

expect "Please select an option below:\r"
send "4\r"

expect "Do you want to view pods in ALL namespaces? Enter 'yes' or 'no':\r"
send "no\r"

expect "Enter the name of the namespace that you wish to view pods in:\r"
send "kube-system\r"

expect "Do you want to continue? Enter 'yes' or 'no':\r"
send "no\r"

expect eof