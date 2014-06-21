#!/bin/bash

# Let everything init a bit before we attach the monitor process
sleep 120

while : 
  do 
  /usr/local/bin/serialpoller.pl
  sleep 30
done


