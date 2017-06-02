import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import csv
import fnmatch
import os
import os.path, time
import sys
import datetime

# wd 
wd = "/home/fripi/correlaid/correlaid-utils/mailchimp-welcomemail/"

# construct the filename of new_xxxx-xx-xx.csv
# this is done to check whether the file exists / whether R file was sucessful
now = datetime.datetime.now()
print("log: " + str(now))

# add leading zero to day and month if < 10
if now.month < 10:
    month_str = '0' + str(now.month)
else:
    month_str = str(now.month)
if now.day < 10:
    day_str = '0' + str(now.day)
else:
    day_str = str(now.day)

filename = 'sendto_' + str(now.year) + '-' + month_str + '-' + day_str + '.csv'
# filename = 'current_' + str(now.year) + '-' + month_str + '-' + day_str + '.csv'



# loop through files in directory and look for the file 
filefound = False
for fp in os.listdir(wd):
    if fnmatch.fnmatch(fp, filename):
        filefound = True
        break

if filefound == False:
    sys.exit("Current sendto file not found")

# check whether there are new people to send an email to
newsubs = 0
with open(wd + filename, "r") as newfile:
    reader = csv.reader(newfile, delimiter=",", quotechar="\"")
    # skip first line
    next(reader)
    # go through new lines
    for row in reader:
        newsubs += 1

if newsubs == 0:
    sys.exit("No new subscribers.")

# read login data into a dictionary
emaild = {}
with open(wd + "aux_data/maillogin.txt") as loginfile:
    for line in loginfile:
        (key, val) = line.split(":")
        emaild[key] = val.strip()  # strip possible whitespace

# set up server
server = smtplib.SMTP(emaild['server'], int(emaild['port']))

server.ehlo()
server.starttls()
server.ehlo()

server.login(emaild['usr'], emaild['pw'])

# set up the message
## read in the html 
htmlfile_de = open(wd + "mail_html/welcomemail_de.html", "r")
htmltext_de = htmlfile_de.read()
htmlfile_de.close()

htmlfile_en = open(wd + "mail_html/welcomemail_en.html", "r")
htmltext_en = htmlfile_en.read()
htmlfile_en.close()

# loop through the file with the new members and send email to them
# if we arrive here, we know that filename exists 
with open(wd + filename, "r") as newfile, open(wd + "sent_total.csv", "a+") as allsent:
    reader = csv.reader(newfile, delimiter=",", quotechar="\"")
    writer = csv.writer(allsent, delimiter=",")
    # skip first line
    next(reader)
    # go through new lines
    for row in reader:
        print(row[2])
        if row[2] == "Englisch":
            msg = MIMEText(htmltext_en, 'html', 'utf-8')
            per_text = htmltext_en.replace('FIRSTNAME', row[1])
            msg = MIMEText(per_text, 'html', 'utf-8')
            msg['Subject'] = "Welcome to CorrelAid"
        elif row[2] == "Deutsch":
            msg = MIMEText(htmltext_en, 'html', 'utf-8')
            per_text = htmltext_de.replace('FIRSTNAME', row[1])
            msg = MIMEText(per_text, 'html', 'utf-8')
            msg['Subject'] = "Willkommen bei CorrelAid"

        msg['From'] = emaild['from']
        msg['To'] = row[0]

        server.sendmail(emaild['usr'], row[0], msg.as_string())
        todaystr = str(now.year) + "-" + month_str + "-" + day_str
        writer.writerow([row[0], row[1], row[2], todaystr])
        print("sent email to " + row[1] + " (" + row[0] + ")")

    print("sent emails to " + str(newsubs) + " people.")

'''
# test addresses
# open the file with the addresses and loop over them 
f = open("testaddr.txt", "r")
for line in f:
    print(line)
    msg['To'] = line
    server.sendmail(emaild['usr'], line, msg.as_string())

f.close()
'''
# remove the "new" file
os.remove(wd + filename)
server.quit()
