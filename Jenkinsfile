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
        }
        failure {
            echo '❌ Build failed. Open Console Output for details.'
        }
    }
}
