import tweepy
import facebook
from mailchimp3 import MailChimp
import MySQLdb
from datetime import date
import os 
import pymysql.cursors
import pymysql

def get_correlaid_data():
    data = {}

    # collect from social media
    data['twitter_follower'] = get_twitter_follower_count()
    data['facebook_likes']  = get_facebook_likes()
    data['newsletter_subs']  = get_newsletter_subs()

    # date and day of week
    today = date.today()
    data['day_of_week'] = today.weekday() # monday is zero
    data['date'] = str(today)
    print(data)

    # connect to database 
    conn = MySQLdb.connect(host = os.environ['DB_HOST'], 
                            user = os.environ['DB_USER'],
                            passwd = os.environ['DB_PWD'], 
                            db = os.environ['DB_DB'])
    cursor = conn.cursor()

    # just for documentation:
    # the table was created using create_table(cursor) (see below)
    # !! do NOT re-execute/uncomment this !!
    # create_table()

    insert_data(cursor, data)

    """
    # fetch data 
    cursor.execute(
        SELECT * FROM correlaid_data
    )

    r = cursor.fetchall() 
    print(r)
    """
    cursor.close()
    # close database connection
    conn.commit()
    conn.close()

def create_table(cursor):
    """
    WARNING: only for documentation purposes to show the specification of the table.
    """

    cursor.execute(
        """
        CREATE TABLE correlaid_data ( 
            date VARCHAR(100) PRIMARY KEY,
            day_of_week INT,
            facebook_likes INT,
            twitter_follower INT,
            newsletter_subs INT
        )
        """
    )

def insert_data(cursor, data):
   cursor.execute(
       """
        INSERT INTO correlaid_data (date, day_of_week, facebook_likes, twitter_follower, newsletter_subs)
        VALUES (%s, %s, %s, %s, %s)
       """, (data['date'], data['day_of_week'], data['facebook_likes'], data['twitter_follower'], data['newsletter_subs']))

def get_twitter_follower_count():
    consumer_key = os.environ['TWITTER_CONSUMER_KEY']
    consumer_secret = os.environ['TWITTER_CONSUMER_SECRET']
    access_token = os.environ['TWITTER_ACCESS_TOKEN']
    access_secret = os.environ['TWITTER_ACCESS_SECRET']

    try:
        # authentification and api creation
        auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
        auth.set_access_token(access_token, access_secret)
        api = tweepy.API(auth)

        u = api.get_user("CorrelAid")
        twitter_follower = u.followers_count
    except:
        twitter_follower = None
    finally:
        return twitter_follower


def get_facebook_likes():
    token = os.environ['FACEBOOK_PAGE_TOKEN']
    try:
        graph = facebook.GraphAPI(access_token=token)
        id = os.environ['FACEBOOK_PAGE_ID']
        res = graph.get_object(id, fields="fan_count")
        likes = res['fan_count']
    except Exception as e:
        print(e)
        likes = None
    finally:
        return likes


def get_newsletter_subs():
    apikey = os.environ['MAILCHIMP_API_KEY']
    try: 
        client = MailChimp(os.environ['MAILCHIMP_USER'], apikey)
        l = client.lists.get(list_id=os.environ['MAILCHIMP_LIST_ID'])
        newsletter_subs = l['stats']['member_count']
    except Exception as e:
        print(e)
        newsletter_subs = None
        pass
    return newsletter_subs
