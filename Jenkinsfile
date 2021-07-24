pipeline {
    
    environment {
        imagename_prod = "jasnicahuang/sosmed"
        imagename_stage = "jasnicahuang/sosmed-stage"
        registryCredential = 'docker_hub_login'
        dockerImage_prod = ''
        dockerImage_stage = ''
    }

    agent any 

    stages {
        
        stage('Prepare workspace') {
            steps {
                echo 'Prepare workspace'

                // Clean workspace
                step([$class: 'WsCleanup'])

                // Checkout git
                checkout scm
            }
        }
       
        stage('Cloning Git') { 
            steps {
                script {
                    if (env.BRANCH_NAME == 'staging') {
                        git branch: 'staging', credentialsId: 'github_key', url: 'https://github.com/Jasnicahuang/bp-sosmed.git'
                    }
                    else if (env.BRANCH_NAME == 'master') {
                        git credentialsId: 'github_key', url: 'https://github.com/Jasnicahuang/bp-sosmed.git'
                    }
                    else {
                        echo 'This is not master or staging'
                    }
                }
            }
        }

        stage('Building Image Staging') { 
            when {
                branch 'staging'
            }
            steps {
                script {
                        dockerImage_stage = docker.build imagename_stage     
                }
                script{
                    try {
                        sh 'docker rmi -f $(docker images -q -f dangling=true)'
                    }
                    catch(Exception e){
                        echo ' No dangling images found. '
                    }
                }
            }     
        }

        stage('Building Image Production') { 
            when {
                branch 'master'
            }
            steps {
                script {
                        dockerImage_prod = docker.build imagename_prod   
                }
                script{
                    try {
                        sh 'docker rmi -f $(docker images -q -f dangling=true)'
                    }
                    catch(Exception e){
                        echo ' No dangling images found. '
                    }
                }
            }     
        }
        
        stage('Push Image Staging to DockerHub') { 
            when {
                branch 'staging'
            }
            steps {
                script {
                        docker.withRegistry('', registryCredential) 
                        {
                            dockerImage_stage.push("$BUILD_NUMBER")
                            dockerImage_stage.push('latest')

                            sh "docker rmi $imagename_stage:$BUILD_NUMBER"
                            sh "docker rmi $imagename_stage:latest"
                        }   
                }
            }
        }

        stage('Push Image Production to DockerHub') { 
            when {
                branch 'master'
            }
            steps {
                script {
                        docker.withRegistry('', registryCredential) 
                        {
                            dockerImage_prod.push("$BUILD_NUMBER")
                            dockerImage_prod.push('latest')

                            sh "docker rmi $imagename_prod:$BUILD_NUMBER"
                            sh "docker rmi $imagename_prod:latest"
                        }   
                }
            }
        }
        
       stage('Deploy To Staging') {
           when {
               branch 'staging'
           }
           steps {
               //sh 'sed -i \'s/$imagename_stage:latest/$imagename_stage:${BUILD_NUMBER}/g\' kube-landing-page/staging-landing-page-deploy.yaml'
               sh 'sudo -u ubuntu -H sh -c "kubectl apply -f kube-sosmed/staging-sosmed-deploy.yaml -n staging"'
               sh 'sudo -u ubuntu -H sh -c "kubectl set image deployment.apps/sosmed-deployment sosmed-deployment=$imagename_stage:${BUILD_NUMBER} --record -n staging"'                 
               
               script {
                   try {
                       sh '''#!/bin/bash -xe
                       sudo -u ubuntu -H sh -c "kubectl get rs -n staging | grep "0" | cut -d' ' -f 1 | xargs kubectl delete -n staging rs"
                       '''
                   }
                   catch(Exception e) {
                       echo ' No replica set found. '
                   }
               }
           }
       }
       
       stage('Deploy To Production') {
           when {
               branch 'master'
           }
           steps {
               //sh "sed -i \'s/$imagename_prod:latest/$imagename_prod:${BUILD_NUMBER}/g\' kube-landing-page/production-landing-page-deploy.yaml"
               sh 'sudo -u ubuntu -H sh -c "kubectl apply -f kube-sosmed/production-sosmed-deploy.yaml -n production"'
               sh 'sudo -u ubuntu -H sh -c "kubectl set image deployment.apps/sosmed-deployment sosmed-deployment=$imagename_prod:${BUILD_NUMBER} --record -n production"'

               script {
                   try {
                       sh '''#!/bin/bash -xe
                       sudo -u ubuntu -H sh -c "kubectl get rs -n production | grep "0" | cut -d' ' -f 1 | xargs kubectl delete -n production rs"
                       '''
                   }
                   catch(Exception e) {
                       echo ' No replica set found. '
                   }
               }
           }
       }  
    }
}
