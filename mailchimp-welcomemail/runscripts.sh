#!/bin/bash

Rscript /home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/get_new_subs.R

python3 /home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/send_mails.py &> /home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/logs/log_send_mails.txt

python3 /home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/send_logs.py
