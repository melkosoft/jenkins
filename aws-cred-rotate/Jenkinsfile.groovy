pipeline {
  agent any
  stages {
    stage("Rotate keys") {
      steps {
         script {
            withAWS( credentials: 'main-jenkins', region: 'us-west-2') {
              sh 'aws-cred-rotate/rotate_groovy.sh -i test1-jenkins -u test1-jenkins -d 0 -o params.txt'
            }
            FOOBAR = readFile('aws-cred-rotate/params.txt').trim()
         }
      }
    }
    stage("Stage Execute") {
       environment {
          MY_SCRIPT_RETURN = "${FOOBAR}"
       }
       steps {
          script {
             def code = load 'aws-cred-rotate/credentials_groovy.groovy'
             code.updateCredential(env.MY_SCRIPT_RETURN)
          }
       }
    }
  }
}
