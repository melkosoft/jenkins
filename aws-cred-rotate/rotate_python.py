import logging
import argparse
import json
from time import gmtime, strftime
from datetime import datetime

from botocore.exceptions import ClientError
import boto3

import requests

logger = logging.getLogger(__name__)

iam = boto3.resource('iam')

def create_key(user_name):
    err = 0
    try:
        key_pair = iam.User(user_name).create_access_key_pair()
        logger.info("Created access key pair for %s. Key ID is %s.", key_pair.user_name, key_pair.id)
        #logger.debug("Key Secret: %s.", key_pair.secret)
    except ClientError:
        key_pair = "Couldn't create access key pair for " + user_name
        logger.exception(key_pair)
        err = 1
    finally:
        return (err,key_pair)


def delete_key(user_name, key_id):
    err = 0
    try:
        key = iam.AccessKey(user_name, key_id)
        key.delete()
        err_msg = "Deleted access key "+key.id+" for "+key.user_name
        logger.info(err_msg)
    except ClientError:
        "Couldn't delete key " + key_id + " for " + user_name
        logger.exception(err_msg)
        err = 1
    finally:
        return (err,err_msg)

def activate_key(user_name, key_id):
    err = 0
    try:
        key = iam.AccessKey(user_name, key_id)
        key.activate()
        err_msg = "Activated access key " + key.id + " for " + key.user_name
        logger.info( err_msg )
    except ClientError:
        err = 1
        err_msg = "Couldn't activate key " + key_id + " for " + user_name
        logger.exception(err_msg)
    finally:
        return (err, err_msg)

def deactivate_key(user_name, key_id):
    err = 0
    try:
        key = iam.AccessKey(user_name, key_id)
        key.deactivate()
        err_msg = "Deactivated access key " + key.id + " for " + key.user_name
        logger.info(err_msg)
    except ClientError:
        err = 1
        err_msg = "Couldn't deactivate key " + key_id + " for " + user_name
        logger.exception(err_msg)
    finally:
        return (err, err_msg)


def list_keys(user_name):
    err = 0
    try:
        keys = list(iam.User(user_name).access_keys.all())
        logger.info("Got %s access keys for %s.", len(keys), user_name)
    except ClientError:
        err = 1
        keys = "Couldn't get access keys for " + user_name
        logger.exception(keys)
    finally:
        return (err, keys)


def rotate_key(user_name, keyid, maxDays):
    (err,all_keys) = list_keys(user_name)
    if err:
       return (err,all_keys)
    for key in all_keys:
           if key.id == keyid:
               CreateDate = key.create_date
               todaysDate = datetime.now().astimezone()
               totalDays =  abs((CreateDate - todaysDate).days)
               if totalDays <= maxDays:
                       logger.info("Key ID: %s, Key Age: %s", key.id, (totalDays-1))
                       return (err, "")
               (err, err_msg) = deactivate_key(user_name, keyid) 
               if not err:
                  break
               else:
                  return (err, err_msg)    
    if len(all_keys) > 1:
              k = 1 if all_keys[0].id == keyid else 0
              (err, msg) = delete_key(user_name, all_keys[k].id)
              if err:
                 return (err, msg)
              logger.info("There are %s keys, deleted key: %s", len(all_keys), all_keys[k].id)
    return create_key(user_name)


def jenkins_api(cmd, url, auth, json):
    if cmd.lower() == "post":
       api_call = requests.post
    elif cmd.lower() == "get":
       api_call = requests.get
    else:
       err_msg = "HTTP command <"+cmd+"> does not supported"
       api_call = lambda url, auth, json: { {status_code:"400", text: err_msg} }
    try:
       req = api_call(url, json=json, auth=auth )
    except requests.exceptions.RequestException as e:
       logger.error(str(e))
       req = {status_code: "400", text: str(e)}
    finally:
       return req

def rotate_jenkins_secret(jenkins_url, auth, id, old_key, new_key, new_secret):
    url = jenkins_url+"/scriptler/run/credentials_python.groovy"
    data = {"credential_id": id, "old_access_key_id": old_key, 
            "new_access_key_id": new_key, "new_secret_key": new_secret}
    print(jenkins_api('post', url, auth = auth, json = data).text) 


def main():
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', action='store', help='Jenkins server url: http://jenkins:8080', default="http://jenkins:8080")
    parser.add_argument('--user', action='store', help='Jenkins user', default="admin")
    parser.add_argument('--token', action='store', help='Jenkins user api token', default="11272410f9c72f0795269ce4c24622604e")
    parser.add_argument('--iam', action='store', help='IAM user', default="test1-jenkins")
    parser.add_argument('--credid', action='store', help='Jenkins credential id', default="")
    parser.add_argument('--keyid', action='store', help='Key Id', default="ASDFGHJKLOIUY")
    parser.add_argument('--age', type=int, action='store', help='Max credentials age', default=50)
    args = parser.parse_args()

    credential_id = args.keyid if args.credid == "" else args.credid
       
    # Error: Secret Not Found - need to create key pair
    err, key_pair = rotate_key(args.iam, args.keyid, args.age)  
    if err:
       print(key_pair)
    else:
      if key_pair != "":
         rotate_jenkins_secret(args.url, (args.user,args.token), args.iam, args.keyid, key_pair.id, key_pair.secret)
    return err

if __name__ == '__main__':
    main()

