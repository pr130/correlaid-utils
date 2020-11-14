# correlaid-utils
This repository contains utility tools for CorrelAid.

:warning: Code in mailchimp-welcomemail is very outdated! Code was developed by [Frie](https://github.com/friep) back in 2017 but has not been actively used / maintained since 2018. The repository was solely open sourced for the purpose of Frie's talk at the [Open Online Data Meetup](https://www.eventbrite.com/e/the-lazy-data-scientist-automating-things-feat-r-python-aws-and-a-pi-registration-121498787143). Code in `correlaid-analytics` has been updated for another upcoming talk in November 2020 but please still proceed with caution :warning: 

Relevant older versions of this repository: 
- [correlaid-analytics Python / Serverless version](https://github.com/friep/correlaid-utils/releases/tag/serverless-python)
- [correlaid-analytics old R version](https://github.com/friep/correlaid-utils/releases/tag/rstats-old)

## mailchimp-welcomemail
This folder contains the code to automatically send out the welcome email to new subscribers to our newsletter once a day. 

### How does it work?
All the code resides on a raspberry pi which is located in @friep's flat. The individual steps are all wrapped in a bash file (runscripts.sh) that executes the scripts in their order. This bash file itself is scheduled to run each night on the raspberry pi using cronjobs. 

The scripts are in the order they are executed by runscripts.sh: 
1. get_new_subs.R: query the Mailchimp API for our newsletter subscriber list and write newly subscribed users to a temporary csv file.
2. send_mails.py: read in the temporary file and send out mails to the newly subscribed users by connecting to our mail server.
3. send_logs.py: send log files to @friep's correlaid address.

## correlaid-analytics
Code to get twitter follower, facebook likes, newsletter subscriber count and general network data on a daily basis using [{smcounts}](https://github.com/friep/smcounts). 

### Deployment on Raspberry Pi
```
install.packages("bspm")
bspm::enable()
install.packages("remotes")
install.packages("cronR")
```

1. install [{smcounts}](https://github.com/friep/smcounts) and its dependencies
2. copy `.Renviron` with all necessary environment variables to Raspberry Pi. Copy `rtweet_token.rds` and `.slackr` as well.
3. run `cron.R` to set up cron job.
