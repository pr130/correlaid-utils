library(cronR)
# RUN ONCE TO CONFIGURE CRONJOB
f <- normalizePath(here::here("correlaid-analytics", "run.R"))
cmd <- cron_rscript(f, workdir = "/home/frie/correlaid-utils", log_append = FALSE)
cmd

cron_add(command = cmd, frequency = 'daily', at = "23:50", id = 'daily_analytics', description = 'Get daily CorrelAid Analytics')
cron_njobs()
cron_ls()