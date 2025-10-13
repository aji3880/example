pipeline {
    agent any

    environment {
        NAMESPACE = "contoh-deployment"
        APP_NAME = "contoh-deployment"
        OCP_API = "https://api.cluster-lqscz.dynamic.redhatworkshops.io:6443"
        OCP_CREDENTIALS = "sha256~VT69KSY0TZCaul1EsomGp1WsYpDZn4USzDNuqUHIDDY"  // sebaiknya pakai Jenkins Credentials, bukan hardcode
        HELM_VERSION = "v3.15.4"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Login to OpenShift') {
            steps {
                withCredentials([string(credentialsId: 'o028545c9-b6ac-4680-bb00-2f91475a7d0e', variable: 'OC_TOKEN')]) {
                    sh """
                    oc login ${OCP_API} --token=${OC_TOKEN} --insecure-skip-tls-verify=true
                    if ! oc get project ${OCP_NAMESPACE} >/dev/null 2>&1; then
                    oc new-project ${OCP_NAMESPACE} --description="Project for ${APP_NAME}"
                    fi
                    oc project ${OCP_NAMESPACE}
                    """
                }
            }
        }

        stage('Ensure BuildConfig exists') {
            steps {
                sh """
                if ! oc get bc ${APP_NAME} -n ${NAMESPACE}; then
                  oc new-build --name=${APP_NAME} --binary --strategy=docker -n ${NAMESPACE}
                fi
                """
            }
        }

        stage('Build in OpenShift') {
            steps {
                sh """
                oc start-build ${APP_NAME} --from-dir=. --follow -n ${NAMESPACE}
                """
            }
        }

        stage('Install Helm') {
            steps {
                sh """
                curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz
                tar -xzf helm.tar.gz
                mkdir -p \$WORKSPACE/bin
                mv linux-amd64/helm \$WORKSPACE/bin/helm
                export PATH=\$WORKSPACE/bin:\$PATH
                \$WORKSPACE/bin/helm version
                """
            }
        }

        stage('Deploy with Helm') {
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

        stage('Deploy to OpenShift') {
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
