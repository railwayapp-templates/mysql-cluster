FROM mysql:9

COPY ./setup.sh /setup.sh
COPY ./initCluster.js /initCluster.js
RUN chmod +x /setup.sh

ENTRYPOINT ["/setup.sh"]
