pipeline {
  agent any
  stages {
    stage("Rotate keys") {
      agent {
        node {
          label "master"
        }
      }
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
      agent {
        node {
          label "master"
        }
      }
       environment {
          MY_SCRIPT_RETURN = "${FOOBAR}"
       }
       steps {
          script {
             def code = load 'credentials_groovy.groovy'
             code.updateCredential(env.MY_SCRIPT_RETURN)
          }
       }
    }
  }
}
