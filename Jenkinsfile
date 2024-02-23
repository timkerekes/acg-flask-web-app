// def dockerBuildAndPush() {
//     withCredentials([usernamePassword(credentialsId: 'HUB_CREDENTIALS_ID', usernameVariable: 'HUB_USERNAME', passwordVariable: 'HUB_PASSWORD')]) {
//         script {
//             def imageName = "${HUB_USERNAME}/acg-flask-web-app:${GIT_COMMIT}"
//             docker.build(imageName, '.').push('latest')
//         }
//     }
// }


// def createEnvFile() {
//     sh '''
//     cd /home/jenkins/workspace/acg-flask-web-app_main
//     touch .env
//     echo "${SERVER_ENV_PROD}" > .env
//     '''
// }

// def removeWorkspaceFolder() {
//     sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
//         sh '''
//         ssh cloud_user@${HOST} -tt "cd ~ && rm -rf workspace"
//         '''
//     }
// }

// def scpUpload() {
//     script {
//         def sourceDir = "/home/jenkins/workspace/acg-flask-web-app_main"
//         def remoteDir = "~/workspace"

//         sshPublisher(
//             publishers: [sshPublisherDesc(
//                 configName: 'SSH_SERVER_CONFIG_NAME',
//                 transfers: [sshTransfer(
//                     source: sourceDir,
//                     destination: remoteDir,
//                     removePrefix: sourceDir
//                 )]
//             )]
//         )
//     }
// }

// def runDockerComposeUp() {
//     sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
//         sh '''
//         ssh cloud_user@${HOST} -tt "cd ~/workspace && docker compose down --remove-orphans && docker compose up -d --build && docker ps"
//         '''
//     }
// }

// def flaskDBMigrateAndUpgrade() {
//     sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
//         sh '''
//         ssh cloud_user@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db init'"
//         ssh cloud_user@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db migrate'"
//         ssh cloud_user@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db upgrade'"
//         '''
//     }
// }

pipeline {
    agent { label 'docker' }
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Build Image') {
            steps {
                script {
                    def buildSuccessful = false

                    try {
                        deleteDir()
                        checkout scm
                        
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
                CONTAINER_NAME = 'workspace-webapp-1'
            }

            stages {
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
                    
                }
                stage('Create Env File') {
                    steps {
                        script {
                            sh('echo $ENV_PROD > .env')
                        }
                    }
                }
                stage('Docker Compose Up') {
                    steps {
                        script {
                            sh "docker compose down --remove-orphans && docker compose up -d --build && docker ps"
                        }
                    }
                }
                stage('Flask DB Migrate & Upgrade') {
                    steps {
                        script {
                            sh """
                                docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db init'
                                docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db migrate'
                                docker exec -w /app/notes ${CONTAINER_NAME} /bin/sh -c 'flask db upgrade'
                            """
                        }
                    }
                }
            }
        }
    }
}
