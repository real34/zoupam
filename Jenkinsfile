#!groovy

node('master') {

    currentBuild.result = "SUCCESS"

    try {

       stage 'Checkout'

            echo 'Fetching the latest version'
            checkout scm

       stage 'Test'

            echo 'Testing the code'
            sh 'make install'
            sh 'make test'
            // env.NODE_ENV = "test"

            // print "Environment will be : ${env.NODE_ENV}"

            // sh 'node -v'
            // sh 'npm prune'
            // sh 'npm install'
            // sh 'npm test'

       stage 'Deploy'
            if (currentBuild.result == 'SUCCESS') {
                if (BRANCH_NAME=='master') {
                    withCredentials([string(credentialsId: 'DEPLOYMENT_PROD_TARGET_PATH', variable: 'DEPLOYMENT_TARGET_PATH')]) {
                        echo 'Build project and deploy it live'
                        sh 'make deploy_prod'
                    }
                } else {
                    withCredentials([string(credentialsId: 'DEPLOYMENT_FEATURE_TARGET_PATH', variable: 'DEPLOYMENT_TARGET_PATH_BASE')]) {
                        echo 'Build project and deploy it in a feature branch'
                        sh 'DEPLOYMENT_TARGET_PATH=$DEPLOYMENT_TARGET_PATH_BASE/${BRANCH_NAME} make deploy_prod'
                    }
                }
            } else {
                echo 'Not deploying this build because it failed'
            }

       stage 'Cleanup'

            echo 'Cleaning things up'
            // echo 'prune and cleanup'
            // sh 'npm prune'
            sh 'rm -rf node_modules elm-stuff'

            // mail body: 'project build successful',
            //             from: 'xxxx@yyyyy.com',
            //             replyTo: 'xxxx@yyyy.com',
            //             subject: 'project build successful',
            //             to: 'yyyyy@yyyy.com'

        }


    catch (err) {

        currentBuild.result = "FAILURE"

            // mail body: "project build error is here: ${env.BUILD_URL}" ,
            // from: 'jennie@occitech.fr',
            // replyTo: 'tracking@occitech.fr',
            // subject: '[Zoupam] Project build failed',
            // to: 'pierre@occitech.fr'

        throw err
    }

}
