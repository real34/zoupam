#!groovy

stage('Checkout') {
    node {
        echo 'Fetching the latest version'
        checkout scm
    }
}

stage('Test') {
    node {
        echo 'Testing the code and linting'
        sh 'make install'
        sh 'make lint'
        sh 'make test'
    }
}

stage('Deploy') {
    node {
        if (BRANCH_NAME=='master') {
            sshagent(['DEPLOYMENT_PROD_SSH_AGENT']) {
                withCredentials([string(credentialsId: 'DEPLOYMENT_PROD_TARGET_PATH', variable: 'DEPLOYMENT_TARGET_PATH')]) {
                    echo 'Build project and deploy it live'
                    sh 'DEPLOYMENT_TARGET_PATH=$DEPLOYMENT_TARGET_PATH make deploy_prod'
                }
            }
        } else {
            sshagent(['DEPLOYMENT_FEATURE_SSH_AGENT']) {
                withCredentials([string(credentialsId: 'DEPLOYMENT_FEATURE_TARGET_PATH', variable: 'DEPLOYMENT_TARGET_PATH_BASE')]) {
                    echo 'Build project and deploy it in a feature branch'
                    sh 'DEPLOYMENT_TARGET_PATH=$DEPLOYMENT_TARGET_PATH_BASE/$(basename ${BRANCH_NAME}) make deploy_prod'
                }
            }
        }
    }
}

stage('Validation') {
    if (BRANCH_NAME=='master') {
        echo 'Rien à faire, cela a été validé sur la branche ...'
    } else {
        milestone()
        URI=sh(basename ${BRANCH_NAME})
        input message: "Est-ce que la fonctionnalité fonctionne correctement sur https://zoupam-features.occi.tech/" + URI + " ?", ok: 'Je valide !'
        milestone()
    }
}

stage('Cleanup') {
    node {
        echo 'Cleaning things up'
        sh 'docker-compose run --rm --entrypoint rm elm -rf elm-stuff node_modules dist/*'
        if (BRANCH_NAME!='master') {
            sshagent(['DEPLOYMENT_FEATURE_SSH_AGENT']) {
                withCredentials([string(credentialsId: 'DEPLOYMENT_FEATURE_TARGET_PATH', variable: 'DEPLOYMENT_TARGET_PATH_BASE')]) {
                    echo 'Empty remote staging directory'
                    // TODO Find a way to remove the empty directory.
                    // I had issues doing it with the user@host:base/path DEPLOYMENT_TARGET_PATH_BASE value,
                    // maybe splitting it in two variables (hostname and base path) is the only solution...
                    sh 'rsync -avh --delete dist/ ${DEPLOYMENT_TARGET_PATH_BASE}/$(basename ${BRANCH_NAME})'
                }
            }
        }
        // mail body: 'project build successful',
        //             from: 'xxxx@yyyyy.com',
        //             replyTo: 'xxxx@yyyy.com',
        //             subject: 'project build successful',
        //             to: 'yyyyy@yyyy.com'
    }
}
