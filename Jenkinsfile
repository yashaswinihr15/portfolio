pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'portfolio'
        CONTAINER_NAME = 'portfolio-container'
        HOST_PORT      = '8080'
        GITHUB_USER    = 'yashaswinihr15'         // ← your GitHub username
        GITHUB_REPO    = 'portfolio'               // ← your repo name
        GITHUB_BRANCH  = 'main'
    }

    stages {

        stage('Build Docker Image') {
            steps {
                echo '📦 Building Docker image from local files...'
                sh 'docker build -t ${IMAGE_NAME} /workspace/portfolio'
            }
        }

        stage('Stop Old Container') {
            steps {
                echo '🛑 Removing old container if it exists...'
                sh 'docker rm -f ${CONTAINER_NAME} || true'
            }
        }

        stage('Deploy Portfolio') {
            steps {
                echo '🚀 Starting portfolio container...'
                sh 'docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:80 ${IMAGE_NAME}'
                echo "✅ Portfolio is live at http://localhost:${HOST_PORT}"
            }
        }

        stage('Push to GitHub') {
            steps {
                echo '📤 Pushing latest code to GitHub...'
                withCredentials([usernamePassword(
                    credentialsId: 'github-credentials',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        cd /workspace/portfolio

                        git config user.email "jenkins@devops.local"
                        git config user.name  "Jenkins Bot"

                        git add -A

                        if git diff-index --quiet HEAD --; then
                            echo "No new changes to commit. GitHub already up to date."
                        else
                            git commit -m "Auto-deploy: $(date '+%Y-%m-%d %H:%M:%S')"
                            git push https://${GIT_USER}:${GIT_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git ${GITHUB_BRANCH}
                            echo "✅ Code pushed to GitHub."
                        fi
                    '''
                }
            }
        }

    }

    post {
        success {
            echo '🎉 All done! Website deployed + GitHub updated.'
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                withCredentials([string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')]) {
                    sh '''
                        # Grab the latest commit message to show in the notification
                        COMMIT_MSG=$(git log -1 --pretty=%B | tr -d '\n' | tr -d '"')
                        
                        curl -H "Content-Type: application/json" \
                        -X POST \
                        -d "{
                            \"embeds\": [{
                                \"title\": \"🟢 Build Success - ${JOB_NAME} (#${BUILD_NUMBER})\",
                                \"description\": \"Website successfully deployed to production! ✅\\nLatest changes pushed to GitHub. 📤\",
                                \"url\": \"${BUILD_URL}\",
                                \"color\": 3066993,
                                \"fields\": [
                                    {
                                        \"name\": \"Latest Commit\",
                                        \"value\": \"${COMMIT_MSG}\",
                                        \"inline\": false
                                    },
                                    {
                                        \"name\": \"Deployment Status\",
                                        \"value\": \"[Go to Live Website](http://localhost:8080)\",
                                        \"inline\": true
                                    }
                                ]
                            }]
                        }" \
                        $DISCORD_WEBHOOK
                    '''
                }
            }
        }
        failure {
            echo '❌ Build failed. Open Console Output for details.'
            catchError(buildResult: 'FAILURE', stageResult: 'SUCCESS') {
                withCredentials([string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')]) {
                    sh '''
                        curl -H "Content-Type: application/json" \
                        -X POST \
                        -d "{
                            \"embeds\": [{
                                \"title\": \"🔴 Build Failed - ${JOB_NAME} (#${BUILD_NUMBER})\",
                                \"description\": \"The deployment pipeline failed! ❌\\nPlease check the logs to diagnose the issue.\",
                                \"url\": \"${BUILD_URL}console\",
                                \"color\": 15158332
                            }]
                        }" \
                        $DISCORD_WEBHOOK
                    '''
                }
            }
        }
    }
}
