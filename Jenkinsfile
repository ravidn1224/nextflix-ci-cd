pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-login')
        DOCKER_USER = "ravidocker285"
        TMDB_KEY = credentials('TMDB_KEY')
        DOCKER_IMAGE = "ravidocker285/nextflix-app"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/dor-amar/nextflix.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:staging ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh """
                    echo ${DOCKERHUB_TOKEN} | docker login -u ${DOCKER_USER} --password-stdin
                    docker push ${DOCKER_IMAGE}:staging
                    """
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    sshagent(['staging-ssh']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@35.159.70.150 '
                            docker pull ${DOCKER_IMAGE}:staging &&
                            docker stop nextflix || true &&
                            docker rm nextflix || true &&
                            echo "TMDB_KEY=${TMDB_KEY}" > .env &&
                            docker run -d -p 3000:3000 --env-file .env --name nextflix ${DOCKER_IMAGE}:staging
                        '
                        """
                    }
                }
            }
        }

        stage('Deploy to Production (Manual Approval)') {
            steps {
                input message: 'Deploy to production?'
                script {
                    sshagent(['prod-ssh']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@3.120.140.201 '
                            docker pull ${DOCKER_IMAGE}:prod &&
                            docker stop nextflix || true &&
                            docker rm nextflix || true &&
                            echo "TMDB_KEY=${TMDB_KEY}" > .env &&
                            docker run -d -p 3000:3000 --env-file .env --name nextflix ${DOCKER_IMAGE}:prod
                        '
                        """
                    }
                }
            }
        }
    }
}
