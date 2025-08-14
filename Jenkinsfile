pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'salonicg14'
    IMAGE_NAME     = 'hello-jenkins'
    
  }

  options {
    // keep logs/artifacts sane
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  //triggers {
    // If your Jenkins is publicly reachable and webhook added, you can use GitHub hook trigger instead.
    // pollSCM('H/2 * * * *') // Fallback: poll every ~2 minutes
  //}

  stages {
    stage('Checkout') {
      steps {
         git branch: 'main', url: 'https://github.com/SaloniPawar-59/hello-docker-app.git'
      }
    }

    stage('Stamp build metadata into index.html') {
      steps {
        script {
          // Get short commit
          env.SHORT_SHA = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          // Replace placeholders in index.html
          sh """
            sed -i 's/{{BUILD_NUMBER}}/${BUILD_NUMBER}/g' index.html
            sed -i 's/{{GIT_SHA}}/${SHORT_SHA}/g' index.html
          """
        }
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          env.IMAGE_TAG = "${BUILD_NUMBER}-${env.SHORT_SHA}"
          sh """
            docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
            docker tag  ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
          """
        }
      }
    }

    stage('Login & Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
            docker logout || true
          """
        }
      }
    }

    stage('Deploy to Remote Server') {
      steps {
        sshagent(credentials: ['remote-server-ssh']) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@43.205.229.36 \\
              'docker pull ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} && \\
               docker stop ${IMAGE_NAME} 2>/dev/null || true && \\
               docker rm   ${IMAGE_NAME} 2>/dev/null || true && \\
               docker run -d --name ${IMAGE_NAME} --restart unless-stopped -p 80:80 \\
                 ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}'
          """
        }
      }
    }
  }

  post {
    success {
      echo "Deployed ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} to remote."
    }
    failure {
      echo "Build failed. Check console output."
    }
    cleanup {
      sh "docker image prune -f || true"
    }
  }
}
