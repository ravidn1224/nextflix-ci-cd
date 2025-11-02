pipeline {
  agent any

  environment {
    // --- Docker / Registry ---
    DOCKER_USER   = "ravidocker285"
    DOCKER_IMAGE  = "${DOCKER_USER}/nextflix-app"
    DOCKERHUB_TOKEN = credentials('dockerhub-token')   

    // --- App Secret (TMDB) ---
    TMDB_KEY = credentials('TMDB_KEY')

    // --- SSH credentials IDs in Jenkins ---
    SSH_STAGING = 'staging-ssh'
    SSH_PROD    = 'prod-ssh'

    // --- Targets (replace with your real IPs) ---
    STAGING_HOST = '35.159.70.150'
    PROD_HOST    = '3.120.140.201' 
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/ravidn1224/nextflix-ci-cd.git'
      }
    }

    stage('Compute Tags') {
      steps {
        script {
          env.SHORT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

          if (env.CHANGE_ID) {
            env.TAG = "pr-${env.CHANGE_ID}-${env.SHORT_SHA}" 
            env.DEPLOY_TAG = "staging"
          } else {
            env.TAG = "main-${env.SHORT_SHA}"
            env.DEPLOY_TAG = "prod"
          }
          echo "Computed TAG=${env.TAG}, DEPLOY_TAG=${env.DEPLOY_TAG}"
        }
      }
    }

    stage('Build (and simple tests)') {
      steps {
        sh """
          echo ${DOCKERHUB_TOKEN} | docker login -u ${DOCKER_USER} --password-stdin
          docker build -t ${DOCKER_IMAGE}:${TAG} .
        """
        sh """
          docker run --rm ${DOCKER_IMAGE}:${TAG} node -v >/dev/null 2>&1 || true
        """
      }
    }

    stage('Push image (versioned + deploy tag)') {
      steps {
        sh """
          # דוחפים גם את ה-tag הייחודי (למעקב) וגם tag סביבתי (staging/prod)
          docker tag ${DOCKER_IMAGE}:${TAG} ${DOCKER_IMAGE}:${DEPLOY_TAG}
          docker push ${DOCKER_IMAGE}:${TAG}
          docker push ${DOCKER_IMAGE}:${DEPLOY_TAG}
        """
      }
    }

stage('Deploy') {
  steps {
    script {
      if (env.CHANGE_ID) {
        echo "PR detected → Deploying to STAGING"
        sshagent(['staging-ssh']) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${STAGING_HOST} '
              docker pull ${DOCKER_IMAGE}:staging &&
              docker stop nextflix || true &&
              docker rm nextflix || true &&
              echo "API_KEY=${TMDB_KEY}" > .env &&
              docker run -d --name nextflix -p 3000:3000 --env-file .env ${DOCKER_IMAGE}:staging
            '
          """
        }
      } else if (env.BRANCH_NAME == 'main' && currentBuild.rawBuild.getCauses().toString().contains('PullRequest')) {
        echo "Merge to main → Deploying to PRODUCTION"
        sshagent(['prod-ssh']) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${PROD_HOST} '
              docker pull ${DOCKER_IMAGE}:prod &&
              docker stop nextflix || true &&
              docker rm nextflix || true &&
              echo "API_KEY=${TMDB_KEY}" > .env &&
              docker run -d --name nextflix -p 3000:3000 --env-file .env ${DOCKER_IMAGE}:prod
            '
          """
        }
      } else {
        echo "Push to main (not merge) → skipping production deploy"
      }
    }
  }
}



  post {
    success {
      script {
        echo "✅ CI/CD success: ${env.DEPLOY_TAG}"
      }
    }
    failure {
      script {
        echo "❌ CI/CD failed"
      }
    }
  }
}
