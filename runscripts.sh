#!/bin/bash

Rscript get_new_subs.R

python send_mails.py &> log_send_mails.txt

python send_logs.py
