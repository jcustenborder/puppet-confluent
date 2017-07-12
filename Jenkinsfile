#!groovy
node {
    checkout scm

    docker.image('jcustenborder/packaging-centos-7:37').inside {
        stage('bundler') {
            sh 'bundle install'
        }
        stage('spec') {
            sh 'rake spec'
        }
    }
}
