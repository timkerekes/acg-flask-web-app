pipeline {
    agent { label 'docker' }
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Build Image') {
            environment {
                        ENV_PROD = credentials('SERVER_ENV_PROD')
            }

            stages {
                stage('Create Env File') {

                    steps {
                        script {
                            deleteDir()
                            checkout scm

                            def envFile = readFile env.ENV_PROD

                            writeFile file: '.env', text: envFile
                        }
                    }
                }

                stage('Docker Build') {
                    steps {
                        script {
                            def buildSuccessful = false

                            try {
                                withCredentials([usernamePassword(credentialsId: 'HUB_CREDENTIALS_ID', usernameVariable: 'HUB_USERNAME', passwordVariable: 'HUB_PASSWORD')]) {
                                    def imageName = "${HUB_USERNAME}/acg-flask-web-app:${GIT_COMMIT}"
                                    dockerImage = docker.build(imageName, '.')
                                }

                                buildSuccessful = true
                            } catch (Exception e) {
                                echo "Build failed: ${e.getMessage()}"
                            }

                            env.BUILD_SUCCESSFUL = buildSuccessful.toString()
                        }
                    }
                }
            }
        }

        stage('Push Image') {
            when {
                expression { env.BUILD_SUCCESSFUL == 'true' }
            }
            steps {
                script {
                    def pushSuccessful = false

                    try {
                        dockerImage.push('latest')

                        pushSuccessful = true
                    } catch (Exception e) {
                        echo "Push failed: ${e.getMessage()}"
                    }

                    env.PUSH_SUCCESSFUL = pushSuccessful.toString()
                }
            }
        }

        stage('Deploy') {
            agent { label 'app' }

            when {
                expression { env.BUILD_SUCCESSFUL == 'true' && env.PUSH_SUCCESSFUL == 'true' }
            }

            environment {
                ENV_PROD = credentials('SERVER_ENV_PROD')
                CONTAINER_NAME = 'notes_app-webapp-1'
            }

            stages {
                stage('Clean Docker Env') {
                    steps {
                        script {
                            try {
                                sh 'docker rm -vf $(docker ps -aq)'
                            } catch (Exception e) {
                                echo "Delete docker containers & volumes Failed: ${e.getMessage()}"
                            }
                            try {
                                sh 'docker rmi -f $(docker images -aq)'
                            } catch (Exception e) {
                                echo "Delete docker images Failed: ${e.getMessage()}"
                            }
                        }
                    }
                }
                stage('Git Checkout') {
                    steps {
                        script {
                            try {
                                deleteDir()
                            } catch (Exception e) {
                                echo "Delete App Folder Failed: ${e.getMessage()}"
                            }

                            try {
                                checkout scm
                            } catch (Exception e) {
                                echo "Checkout Failed: ${e.getMessage()}"
                            }
                        }
                        
                    }
                    
                }
                stage('Create Env File') {
                    steps {
                        script {
                            def envFile = readFile env.ENV_PROD

                            writeFile file: '.env', text: envFile
                        }
                    }
                }
                stage('Docker Compose Up') {
                    steps {
                        script {
                            sh "docker compose down --remove-orphans && docker compose up -d && docker ps"
                        }
                    }
                }
                stage('Flask DB Migrate & Upgrade') {
                    steps {
                        script {
                            catchError(buildResult: 'SUCCESS') {
                                sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db init'"
                            } onFailure {
                                echo "Flask db init failed: ${error}"
                            }
                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db migrate'"
                            } onFailure {
                                echo "Flask db migrate failed: ${error}"
                            }
                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db upgrade'"
                            } onFailure {
                                echo "Flask db upgrade failed: ${error}"
                            }
                        }
                    }
                }
            }
        }
    }
}
