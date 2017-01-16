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

        // if (BRANCH_NAME=='master' && currentBuild.result == 'SUCCESS') {
            echo 'Build project and deploy it live'
            // The env variable with target must be set. Example: DEPLOYMENT_TARGET_PATH=target@server.tld:path/to/dest
            sh 'make deploy_prod'
        // } else {
        //     echo 'Not deploying this build'
        // }

       stage 'Cleanup'

            echo 'Cleaning things up'
            // echo 'prune and cleanup'
            // sh 'npm prune'
            // sh 'rm node_modules -rf'

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
