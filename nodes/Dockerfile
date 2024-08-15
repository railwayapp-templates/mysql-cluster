FROM mysql:8

COPY my.cnf /etc/mysql/my.cnf
COPY setup.sh /setup.sh

RUN chmod +x /setup.sh

ENTRYPOINT ["/setup.sh"]
