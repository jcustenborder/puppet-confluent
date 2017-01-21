#!groovy
node {
    checkout scm

    docker.image('ruby:2.3.3').inside {
        stage('bundler') {
            sh 'bundle install'
        }
        sh 'useradd --uid 1000 jenkins'
        stage('spec') {
            sh 'rake spec'
        }
    }
}