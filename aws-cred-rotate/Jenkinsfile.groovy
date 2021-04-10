pipeline {
  agent any
  stages {
    stage("Rotate keys") {
      agent {
        node {
          label "awscli"
        }
      }
      steps {
         script {
            withAWS( credentials: 'main-jenkins', region: 'us-west-2') {
              sh 'rotate_groovy.sh -i test2-jenkins -u test2-jenkins -d 0 -o params.txt'
            }
            FOOBAR = readFile('aws/keyrotate/params.txt').trim()
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
