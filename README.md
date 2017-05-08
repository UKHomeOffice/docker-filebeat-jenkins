**User story**

As a member of DevOps team I want to send Jenkins' build logs to [Elastic Stack](https://www.elastic.co/products) so that all logs are available in a central logging system for analysis.

**Requirements:**
- Filebeat container is to be deployed on the same host as Jenkins
- Filebeat container is to be managed by systemd as `filebeat.service`
- Filebeat state has to be persisted on the host
- If Jenkins goes down, Filebeat has to stop too and Filebeat only starts again if Jenkins starts

**Assumptions:**
- Jenkins container is already running with `--name jenkins` docker flag
- Jenkins container is being managed with systemd as `jenkins.service`
- Elasticsearch, Logstash _(optional)_ and Kibana are already running

**Configurations:**
- Edit `config/filebeat.yml` file as appropriate for your system:
    ```
    paths:
      # or legacy jenkins jobs
      - /var/lib/jenkins/jobs/*/builds/*/log
      # For jenkins blue ocean pipeline jobs
      - /var/lib/jenkins/jobs/*/jobs/*/branches/*/builds/*/log

    output.elasticsearch:
      # Array of hosts to connect to.
      hosts: ["HOST_NAME:9200"]
      # Optional protocol and basic auth credentials.
      protocol: "http"
      username: "USER_NAME"
      password: "PASSWORD"
    ```
- Edit `systemd/filebeat.service` file as appropriate for your system. This file declares a dependency on jenkins. So, if jenkins goes down, Filebeat has to go down too. Otherwise Filebeat will not be able to read build logs once Jenkins comes up.

  ```
  After=jenkins.service
  Requires=jenkins.service
  ExecStartPre=-/usr/bin/docker stop filebeat
  ExecStart=/usr/bin/docker run --rm --name filebeat --volume filebeat_data:/data --volumes-from jenkins:ro docker-filebeat-jenkins
  ```
    - **_NOTE:_** `--volume filebeat_data:/data` is required in order to persist Filebeat state. Failing to persist Filebeat state will lead to Filebeat re-sending all build logs to Elasticsearch on restart

**Build Filebeat image**
*
    ```
    docker build --rm --no-cache --tag docker-filebeat-jenkins .
    ```


**Run Filebeat container**<br>
If Jenkins container is stopped, removed and run again, Filebeat will not be able to read Jenkins' log files. Jenkins' container ID would have changed, so Filebeat would have lost the visibility of Jenkins' volume.

Filebeat has a dependency on Jenkins being up and running. So, if Jenkins goes down, Filebeat has to go down at the same
time and both these services have to be brought up again; Jenkins first and Filebeat second
1. Copy all files from the systemd directory in this repo and place them in `/etc/systemd/system` directory on the host
file system
2. Run the following commands: <br>
 ```sudo systemctl enable $(pwd)/systemd/filebeat.service
 sudo systemctl daemon-reload
 sudo systemctl start filebeat.service
 docker ps -a
 ```
 to check if filebeat and jenkins are up and running.

  `docker exec -it filebeat ls -latr /var/lib/jenkins` to see if Jenkins' volume is visible from within Filebeat's
  container

In Kibana, create an index called `logstash-*` to view Jenkins' build logs.

Filebeat documentation: https://www.elastic.co/guide/en/beats/filebeat/current/index.html<br>
Filebeat FAQ: https://www.elastic.co/guide/en/beats/filebeat/current/faq.html
