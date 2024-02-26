pipeline {
    agent { label 'docker' }
    
    environment {
        ENV_PROD = credentials('SERVER_ENV_PROD')
    }

    triggers {
        githubPush()
    }
    
    stages {
        stage('Test Container Name') {
            steps {
                script {
                    sh "echo ${env.JOB_NAME}"
                }
            }
        }
        stage('Build Image') {
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
                CONTAINER_NAME = 'notes_app-webapp-1'
            }

            stages {
                stage('Clean Docker Env') {
                    steps {
                        script {
                            sh "docker compose down -v --remove-orphans"

                            sh 'docker system prune -a --volumes'
                            
                        }
                    }
                }
                stage('Git Checkout') {
                    steps {
                        script {
                            deleteDir()
                            checkout scm
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
                            sh "docker compose up -d && docker ps"
                        }
                    }
                }
                stage('Flask DB Migrate & Upgrade') {
                    steps {
                        script {
                            sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db init'"
                            
                            sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db migrate'"
                            
                            sh "docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db upgrade'"
                        }
                    }
                }
            }
        }
    }
}
