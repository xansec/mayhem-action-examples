pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                echo 'Setting up..'
                withCredentials([usernamePassword(credentialsId: 'MAYHEM_CREDENTIALS', usernameVariable: 'MAYHEM_USERNAME', passwordVariable: 'MAYHEM_TOKEN')]) {
                    sh """
                      # Setup aarch64 (preinstalled) and x86_64 (download to install)
                      mkdir -p ~/bin
                      export PATH=\${PATH}:~/bin
                      curl -Lo ~/bin/mayhem-x86_64 ${MAYHEM_URL}/cli/Linux/mayhem  && chmod +x ~/bin/mayhem-x86_64

                      # Login to mayhem and docker
                      mayhem-\$(arch) login --url ${MAYHEM_URL} --token ${MAYHEM_TOKEN}
                      REGISTRY=\$(mayhem-\$(arch) docker-registry)
                      echo "${MAYHEM_TOKEN}" | docker login -u ${MAYHEM_USERNAME} --password-stdin \${REGISTRY} 
                    """
                }

            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh """
                    echo "Compiling the code..."
                    REGISTRY=\$(mayhem-\$(arch) docker-registry)
                    docker build --platform=linux/amd64 -t \${REGISTRY}/lighttpd:${env.BRANCH_NAME} .
                    docker push \${REGISTRY}/lighttpd:${env.BRANCH_NAME}
                    echo "Compile complete."
                   """
            }
        }
        stage('Mayhem for Code') {
            matrix {
                agent any
                axes {
                    axis {
                        name 'MAYHEMFILE'
                        values 'mayhem/Mayhemfile.lighttpd', 'mayhem/Mayhemfile.mayhemit'
                    }
                }
                stages {
                    stage('Mayhem for Code') {
                        steps {
                            echo 'Scanning..'
                            sh """#!/bin/bash
                                  export PATH=\${PATH}:~/bin   
                                  REGISTRY=\$(mayhem-\$(arch) docker-registry)

                                  # Run Mayhem
                                  # removed --merge-base-branch-name 
                                  # remove --ci-url 
                                  echo "mayhem-\$(arch) --verbosity info run . --project forallsecure/mcode-action-examples --owner forallsecure --image \${REGISTRY}/lighttpd:${env.BRANCH_NAME} --file ${MAYHEMFILE} --regression --coverage --branch-name ${env.BRANCH_NAME} --revision ${env.GIT_COMMIT} 2>/dev/null"
                                  run=\$(mayhem-\$(arch) --verbosity info run . --project forallsecure/mcode-action-examples --owner forallsecure --image \${REGISTRY}/lighttpd:${env.BRANCH_NAME} --file ${MAYHEMFILE} --regression --coverage --branch-name ${env.BRANCH_NAME} --revision ${env.GIT_COMMIT} 2>/dev/null);
                                  # Fail if no output was given
                                  if [ -z "\${run}" ]; then exit 1; fi

                                  # Determine run name
                                  runName=\$(echo \${run} | awk -F / '{ print \$(NF-1) }');

                                  # Wait for job to complete and artifacts to be ready
                                  mayhem-\$(arch) --verbosity info wait \${run} --owner forallsecure --sarif sarif-\${runName}.sarif --junit junit-\${runName}.xml;
                                  status=\$(mayhem-\$(arch) --verbosity info show --owner forallsecure --format json \${run} | jq '.[0].status')
                                  if [[ \${status} == *"stopped"* || \${status} == *"failed"* ]]; then exit 2; fi
                                  defects=\$(mayhem-\$(arch) --verbosity info show --owner forallsecure --format json \${run} | jq '.[0].defects|tonumber')
                                  if [[ \${defects} -gt 0 ]]; then echo "\${defects} defects found!"; exit 3; fi
                               """
                        }
                    }
                }
                post {
                    always {
                        echo 'Archive....'
                        archiveArtifacts artifacts: 'junit-*.xml, sarif-*.sarif',
                           allowEmptyArchive: true,
                           fingerprint: true,
                           onlyIfSuccessful: false
                        junit 'junit-*.xml'
                        recordIssues(
                            enabledForFailure: true,
                            tool: sarif(id: 'sarif-' + env.EXECUTOR_NUMBER, pattern: 'sarif-*.sarif')
                        )
                    }
                }
            }
        }
    }
}
