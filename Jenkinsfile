pipeline {
    agent any
    environment {
        DOCKER_IMAGE_NAME = "timkerekes/acg-flask-web-app"
    }
    stages {
        stage('Build Docker Image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker compose build(DOCKER_IMAGE_NAME)
                }
            }
        }
        stage('Push Docker Image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker_hub') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
        stage('Pull Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker_hub') {
                        app.pull("${env.BUILD_NUMBER}")

                    }
                }
            }
        }
    }
}