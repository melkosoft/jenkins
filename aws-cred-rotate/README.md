## Jenkins job to rotate AWS keys and update credentials in Jenkins
### Requirements:
- Credentials id in Jenkins have to be named the same as IAM users in AWS
- Permissions used by script to rotate IAM keys - in 'iam-access-key.json' file

### 4 Ways to rotate keys:

1. **Jenkins server run:** groovy script and bash script are run on master
   *Requirements*:     **awscli** and **jq** must be installed on master
   *Jenkinsfile:* **Jenkinsfile.master**

2. **Slave+master:** groovy and bash scripts are on slave
   *Requirements:*   
     *slave:* **awscli** and **jq** installed
     *master:* script methods approved (see script-method-approved file)
     *Jenkinsfile:* **Jenkinsfile.groovy**

3. **Slave+system groovy script:** groovy script uploaded on master using scriptler plugin, python script running on slave and run groovy script using API call
   *Requirements:*
     *slave:* **python** with packages: boto3, requests
     *master:* **credentials_python.groovy** with parameters: credential_id, old_access_key_id, new_access_key_id, new_secret_key
             loaded using sriptler plugin GUI. Credentials **api_access_token** with username/password: admin as username and admin token as password
   *Jenkinsfile:* **Jenkinsfile.python**

3. **Slave+system groovy script:** 
   *Requirements:*
     *slave:* **awscli** and **jq**
     *master:* **credentials_system.groovy** with parameters: credential_id, old_access_key_id, new_access_key_id, new_secret_key
             loaded using Sriptler plugin GUI. Credentials **api_access_token** with username/password: admin as username and admin token as password
   *Jenkinsfile:* **Jenkinsfile.system**

