def dockerBuildAndPush() {
    withCredentials([usernamePassword(credentialsId: 'HUB_CREDENTIALS_ID', usernameVariable: 'HUB_USERNAME', passwordVariable: 'HUB_PASSWORD')]) {
        script {
            docker.withRegistry('https://hub.docker.com/timkerekes') {
                def imageName = "${env.HUB_USERNAME}/acg-flask-web-app:${GIT_COMMIT}"
                docker.build(imageName, '.').push()
            }
        }
    }
}

def createEnvFile() {
    sh '''
    cd /home/runner/work/acg-flask-web-app/acg-flask-web-app
    touch .env
    echo "${SERVER_ENV_PROD}" > .env
    '''
}

def removeWorkspaceFolder() {
    sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
        sh '''
        ssh jenkins@${HOST} -tt "cd ~ && rm -rf workspace"
        '''
    }
}

def scpUpload() {
    script {
        def sourceDir = "/home/runner/work/acg-flask-web-app/acg-flask-web-app"
        def remoteDir = "~"

        sshPublisher(
            publishers: [sshPublisherDesc(
                configName: 'SSH_SERVER_CONFIG_NAME',
                transfers: [sshTransfer(
                    source: sourceDir,
                    destination: remoteDir,
                    removePrefix: sourceDir
                )]
            )]
        )
    }
}

def runDockerComposeUp() {
    sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
        sh '''
        ssh jenkins@${HOST} -tt "cd ~/workspace && docker compose down --remove-orphans && docker compose up -d --build && docker ps"
        '''
    }
}

def flaskDBMigrateAndUpgrade() {
    sshagent(['PRIVATE_KEY_CREDENTIALS_ID']) {
        sh '''
        ssh jenkins@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db init'"
        ssh jenkins@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db migrate'"
        ssh jenkins@${HOST} -tt "docker exec -w /app/notes workspace-webapp-1 /bin/sh -c 'flask db upgrade'"
        '''
    }
}

pipeline {
    agent { label 'docker' }
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Build & Push') {
            steps {
                script {
                    def buildSuccessful = false

                    try {
                        checkout scm
                        dockerBuildAndPush()
                        buildSuccessful = true
                    } catch (Exception e) {
                        echo "Build and push failed: ${e.getMessage()}"
                    }

                    // Set environment variable to indicate build status
                    env.BUILD_SUCCESSFUL = buildSuccessful.toString()
                }
            }
        }

        stage('Deploy') {
            when {
                expression { env.BUILD_SUCCESSFUL == 'true' }
            }

            steps {
                script {
                    checkout scm
                    createEnvFile()
                    removeWorkspaceFolder()
                    scpUpload()
                    runDockerComposeUp()
                    flaskDBMigrateAndUpgrade()
                }
            }
        }
    }
}
