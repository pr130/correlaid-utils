import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import os.path, time
import sys

wd = "/home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/"
# read login data into a dictionary
emaild = {}
with open(wd + "aux_data/maillogin.txt") as loginfile:
        for line in loginfile:
                (key, val) = line.split(":")
                emaild[key] = val.strip() # strip possible whitespace

# set up server
server = smtplib.SMTP(emaild['server'], int(emaild['port']))

server.ehlo()
server.starttls()
server.ehlo()

server.login(emaild['usr'], emaild['pw'])


# set up the message 
outer = MIMEMultipart()
outer['Subject'] = "Welcome mail logs" 
outer['From'] = emaild['usr'] 
outer['To'] = emaild['logrec'] 
 

filenames = [wd + "logs/log_send_mails.txt", wd + "logs/log_get_new_subs.txt"]
for filename in filenames:
        log = open(filename)
        msg = MIMEText(log.read())
        log.close()
        msg.add_header('Content-Disposition', 'attachment', filename=filename)
        outer.attach(msg)

composed = outer.as_string()

server.sendmail(emaild['usr'], emaild['logrec'], composed)

server.quit()

