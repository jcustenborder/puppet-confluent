#!groovy

import groovy.json.JsonSlurper


node {
    deleteDir()
    checkout scm

    docker.image('jcustenborder/packaging-centos-7:37').inside {
        stage('bundler') {
            sh 'bundle install'
        }
        stage('spec') {
            sh 'rake spec'
        }

        if (env.BRANCH_NAME == 'master') {
            stage('publish') {
                withCredentials([usernamePassword(credentialsId: 'puppet_forge', passwordVariable: 'BLACKSMITH_FORGE_PASSWORD', usernameVariable: 'BLACKSMITH_FORGE_USERNAME')]) {
                    withEnv(['BLACKSMITH_FORGE_URL=https://forgeapi.puppetlabs.com']) {
                        sh 'rake jenkins_set_version module:tag build module:push'
                    }
                }
            }
        }
    }
}
