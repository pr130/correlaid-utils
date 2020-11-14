library(cronR)
# RUN ONCE TO CONFIGURE CRONJOB
f <- normalizePath("run.R")
f
cmd <- cron_rscript(f)
cmd

cron_add(command = cmd, frequency = 'daily', at = "23:50", id = 'daily_analytics', description = 'Get daily CorrelAid Analytics')
cron_njobs()
cron_ls()
