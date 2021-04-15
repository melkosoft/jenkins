#!/usr/bin/env groovy

import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import jenkins.model.Jenkins


def updateCredential = { id, old_access_key, new_access_key, new_secret_key ->
    println "Running updateCredential: (\"$id\", \"$old_access_key\", \"$new_access_key\", \"************************\")"
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.jenkins.plugins.awscredentials.BaseAmazonWebServicesCredentials.class,
        jenkins.model.Jenkins.instance
    )

    def c = creds.findResult { (it.id == id && it.accessKey == old_access_key) ? it : null }

    if ( c ) {
        println "found credential ${c.id} for access_key ${c.accessKey}"
		println c.class.toString()
        def credentials_store = jenkins.model.Jenkins.instance.getExtensionList(
          'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
        )[0].getStore()
		 def tscope = c.scope as com.cloudbees.plugins.credentials.CredentialsScope
         def result = credentials_store.updateCredentials(
           com.cloudbees.plugins.credentials.domains.Domain.global(),
           c,
           new com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl(tscope, c.id, new_access_key, new_secret_key, c.description, null, null)
         )

        if (result) {
            println "password changed for id: ${id}"
        } else {
            throw  new java.lang.ClassCastException("failed to change password for id: ${id}")
        }
    } else {
      throw  new java.lang.ClassCastException("could not find credential for id: ${id}")
    }
}

def checkCredential = { id, old_access_key ->
    println "Running checkCredential: (\"$id\", \"************************\")"
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.jenkins.plugins.awscredentials.BaseAmazonWebServicesCredentials.class,
        jenkins.model.Jenkins.instance )

    def c = creds.findResult { (it.id == id && it.accessKey == old_access_key) ? it : null }

    if ( c ) {
        println "${c.id},${c.accessKey}"
    } else {
        println ""
    }
}


if ( env['CI_ROTATE_ACTION'] == 'checkkey' ) {
   checkCredential("${env['CI_ROTATE_CREDENTIAL_ID']}")
} else if ( env['CI_ROTATE_CREDENTIAL_ID'] == null || env['CI_ROTATE_NEW_ACCESS_KEY_ID'] == null || env['CI_ROTATE_NEW_SECRET_KEY'] == null || env['CI_ROTATE_OLD_ACCESS_KEY_ID'] == null ||
	env['CI_ROTATE_CREDENTIAL_ID'] == '' || env['CI_ROTATE_NEW_ACCESS_KEY_ID'] == '' || env['CI_ROTATE_NEW_SECRET_KEY'] == '' || env['CI_ROTATE_OLD_ACCESS_KEY_ID'] == '') 
       {
	  println "Missing value for 'CI_ROTATE_CREDENTIAL_ID', 'CI_ROTATE_NEW_ACCESS_KEY_ID', or 'CI_ROTATE_NEW_SECRET_KEY'"
	  println "CI_ROTATE_CREDENTIAL_ID: ${env['CI_ROTATE_CREDENTIAL_ID']}"
	  println "CI_ROTATE_OLD_ACCESS_KEY_ID: ${env['CI_ROTATE_OLD_ACCESS_KEY_ID']}"
	  println "CI_ROTATE_NEW_ACCESS_KEY_ID: ${env['CI_ROTATE_NEW_ACCESS_KEY_ID']}" 
       } 
  else {
	updateCredential("${env['CI_ROTATE_CREDENTIAL_ID']}", "${env['CI_ROTATE_OLD_ACCESS_KEY_ID']}", "${env['CI_ROTATE_NEW_ACCESS_KEY_ID']}", "${env['CI_ROTATE_NEW_SECRET_KEY']}")
}
