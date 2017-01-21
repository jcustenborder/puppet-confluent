#!groovy
node {
    checkout scm

    docker.image('ruby:2.3.3').inside {
        stage('bundler') {
            sh 'bundle install'
        }
        stage('spec') {
            sh 'rake spec'
        }
    }
}