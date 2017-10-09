# correlaid-utils
This repository contains utility tools for CorrelAid.

## mailchimp-welcomemail
This folder contains the code to automatically send out the welcome email to new subscribers to our newsletter once a day. 

### How does it work?
All the code resides on a raspberry pi which is located in @friep's flat. The individual steps are all wrapped in a bash file (runscripts.sh) that executes the scripts in their order. This bash file itself is scheduled to run each night on the raspberry pi using cronjobs. 

The scripts are in the order they are executed by runscripts.sh: 
1. get_new_subs.R: query the Mailchimp API for our newsletter subscriber list and write newly subscribed users to a temporary csv file.
2. send_mails.py: read in the temporary file and send out mails to the newly subscribed users by connecting to our mail server.
3. send_logs.py: send log files to @friep's correlaid address.

## correlaid-analytics
Code to get twitter follower, facebook likes, newsletter subscriber count and general network data on a daily basis. Data from Mondays are uploaded to the FTP Server of the website in order to be visualised. Daily data are uploaded each day to a MongoDB hosted on mlab.com.
