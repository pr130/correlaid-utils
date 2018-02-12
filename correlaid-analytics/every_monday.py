import os 
import pymysql.cursors
import pymysql
import json
from datetime import datetime
import ftplib

def upload_to_ftp(event, context):

    connect to database 
    conn = pymysql.connect(host = os.environ['DB_HOST'], 
                             user = os.environ['DB_USER'],
                             password = os.environ['DB_PWD'], 
                             db = os.environ['DB_DB'])
         
    cursor = conn.cursor()

    cursor.execute(
    """
    SELECT date, facebook_likes, twitter_follower, newsletter_subs
    FROM correlaid_data 
    WHERE day_of_week = 0
    """)

    res = cursor.fetchall()

    # close database connection
    cursor.close()
    conn.close()

    # process 
    data = {}
    days = [tup[0] for tup in res]
    days = [datetime.strptime(day, "%Y-%m-%d") for day in days]
    data['days'] = [day.strftime("%b %d, %Y ") for day in days]

    data['facebook'] = [tup[1] for tup in res]
    data['twitter'] = [tup[2] for tup in res]
    data['newsletter'] = [tup[3] for tup in res]

    print(data)

    # dump to json
    with open("/tmp/weekly_data.json", "w+") as f:
        json.dump(data, f)

    # upload json to ftp server
    ftp_server = os.environ['FTP_SERVER']
    ftp_user = os.environ['FTP_USER']
    ftp_pw = os.environ['FTP_PW']
    
    session = ftplib.FTP(ftp_server, ftp_user, ftp_pw)
    with open('/tmp/weekly_data.json','rb') as f: 
        session.storbinary('STOR all_weekly.json', f)
    session.quit()
    # done

    return build_success_response('successfully uploaded to FTP.')


def build_success_response(string):
    # default response 
    response = {
        "statusCode": 200,
        "body": string
    }
    return response 
