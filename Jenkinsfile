pipeline {

  agent none

  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '15', daysToKeepStr: '90', numToKeepStr: '')
  }

  stages {
    stage('prepare') {
      agent any
      steps {
        sh 'git clean -fdx'
      }
    }
    stage('build docker image') {
      agent any
      steps {
        script{
          docker.withRegistry('https://ghcr.io','jenkins-github-container-registry') {
            dockerimage_public = docker.build("intranda/goobi-rproxy-docker:${env.BUILD_ID}_${env.GIT_COMMIT}")
            //TODO: Activate this once we want the latest build to point to the latest release
            //if (env.GIT_BRANCH == 'origin/master' || env.GIT_BRANCH == 'master') {
            //  dockerimage_public.push("latest")
            //}
            if (env.GIT_BRANCH == 'origin/develop' || env.GIT_BRANCH == 'develop') {
              dockerimage_public.push("develop")
            }
            if (latestTag != '') {
              dockerimage_public.push(latestTag)
            }
          }
        }
      }
    }
  }
  post {
    changed {
      emailext(
        subject: '${DEFAULT_SUBJECT}',
        body: '${DEFAULT_CONTENT}',
        recipientProviders: [requestor(),culprits()],
        attachLog: true
      )
    }
  }
}
/* vim: set ts=2 sw=2 tw=120 et :*/
