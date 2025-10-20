pipeline {
    agent any

    environment {
        NAMESPACE = "contoh-deployment"
        APP_NAME = "contoh-deployment"
        OCP_API = "https://api.cluster-f4k2h.dynamic.redhatworkshops.io:6443"
        //OCP_CREDENTIALS = ""  // sebaiknya pakai Jenkins Credentials, bukan hardcode
        HELM_VERSION = "v3.15.4"
    }

    stages {
        stage('checkout') {
            steps {
                checkout scm
            }
        }

        stage('login') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ocp-crd', usernameVariable: 'OCP_USER', passwordVariable: 'OCP_PASS')]) {
                    sh """
                    oc login ${OCP_API} -u ${OCP_USER} -p ${OCP_PASS} --insecure-skip-tls-verify=true
                    if ! oc get project ${NAMESPACE} >/dev/null 2>&1; then
                    oc new-project ${NAMESPACE} --description="Project for ${APP_NAME}"
                    fi
                    oc project ${NAMESPACE}
                    """
                }
            }
        }

        stage('buildconfig') {
            steps {
                sh """
                if ! oc get bc ${APP_NAME} -n ${NAMESPACE}; then
                  oc new-build --name=${APP_NAME} --binary --strategy=docker -n ${NAMESPACE}
                fi
                """
            }
        }

        stage('Build openshift') {
            steps {
                sh """
                oc start-build ${APP_NAME} --from-dir=. --follow -n ${NAMESPACE}
                """
            }
        }

        stage('install helm') {
            steps {
                sh """
                curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz
                tar -xzf helm.tar.gz
                mkdir -p "\$WORKSPACE/bin"
                mv linux-amd64/helm "\$WORKSPACE/bin/helm"
                export PATH="\$WORKSPACE/bin:\$PATH"
                "\$WORKSPACE/bin/helm" version
                """
            }
        }

        stage('deploy helm') {
            steps {
                sh """
                export PATH=\$WORKSPACE/bin:\$PATH
                helm upgrade --install ${APP_NAME} ./helm-chart \\
                  --set image.repository=image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/${APP_NAME} \\
                  --set image.tag=latest \\
                  -n ${NAMESPACE} --create-namespace
                """
            }
        }

        stage('deploy oc') {
            steps {
                script {
                    sh """
                    oc rollout restart deployment ${APP_NAME} -n ${NAMESPACE}
                    """
                }
            }
        }
    }
}
