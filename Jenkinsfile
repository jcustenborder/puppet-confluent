#!groovy
node {
    checkout scm

    docker.image('jcustenborder/packaging-centos-7:36').inside {
        stage('bundler') {
            sh 'bundle install'
        }
        stage('spec') {
            sh 'rake spec'
        }
    }
}
