pipeline {
  agent {
    label "docker"
  }
  parameters {
    string(name: "UPLOADER_COMMIT", defaultValue: "", description: "Force revision to this specific commit")
    booleanParam(name: "SKIP_INTEGRATION", defaultValue: false, description: "Whether integration should be skipped")
    string(name: "CELL_NUMBER", defaultValue: "1", description: "Integration. Number of cells to deploy")
  }
  stages {
    stage("Retrieve build environment") {
      steps {
        script {
          if (params.UPLOADER_COMMIT) {
            GIT_COMMIT = params.UPLOADER_COMMIT
            sh("git checkout -fb integration ${params.UPLOADER_COMMIT}")
          }
        }
        script {
          GIT_COMMIT_MESSAGE = sh(returnStdout: true, script: "git rev-list --format=%B --max-count=1 ${GIT_COMMIT}").trim()
        }
      }
    }
    stage("Build image") {
      steps {
        script {
          docker.build("smartbox/uploader:${GIT_COMMIT}")
        }
      }
    }
    stage("Analyze image") {
      steps {
        sh("docker run --rm smartbox/uploader:${GIT_COMMIT} bundle exec rubocop --no-color -D")
      }
    }
    stage ("Build production image") {
      steps {
        script {
          docker.build("smartbox/uploader:${GIT_COMMIT}-production", "-f Dockerfile .")
        }
      }
    }
    stage ("Internal publish") {
      steps {
        script {
          docker.withRegistry("https://registry.smartbox.io/") {
            docker.image("smartbox/uploader:${GIT_COMMIT}-production").push(GIT_COMMIT)
          }
        }
      }
    }
    stage("Run integration tests") {
      steps {
        script {
          build job: "integration/master", parameters: [
            text(name: "COMMIT_MESSAGE", value: GIT_COMMIT_MESSAGE),
            string(name: "UPLOADER_COMMIT", value: GIT_COMMIT),
            string(name: "CELL_NUMBER", value: params.CELL_NUMBER)
          ]
        }
      }
    }
    stage("Publish") {
      when { expression { BRANCH_NAME == "master" && !params.SKIP_INTEGRATION } }
      steps {
        script {
          docker.withRegistry("https://registry.hub.docker.com", "docker-hub-credentials") {
            docker.image("smartbox/uploader:${GIT_COMMIT}-production").push("latest")
          }
        }
      }
    }
  }
  post {
    always {
      sh("docker rmi -f --no-prune smartbox/uploader:${GIT_COMMIT}")
      sh("docker rmi -f --no-prune smartbox/uploader:${GIT_COMMIT}-production")
      sh("docker rmi -f --no-prune registry.hub.docker.com/smartbox/uploader:latest")
      sh("docker rmi -f --no-prune registry.smartbox.io/smartbox/uploader:${GIT_COMMIT}")
    }
  }
}