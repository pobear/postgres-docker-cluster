FROM postgres:9.5.4
ARG POSTGRES_VERSION=9.5

RUN echo deb http://debian.xtdv.net/debian jessie main > /etc/apt/sources.list && apt-get update
RUN apt-get install -y postgresql-server-dev-$POSTGRES_VERSION postgresql-$POSTGRES_VERSION-repmgr openssh-server
RUN apt-get install -y wget make gcc zlib1g-dev libkrb5-dev libssl-dev
# RUN wget http://ftp.debian.org/debian/pool/main/o/openssl/libssl-dev_1.0.1t-1+deb8u6_amd64.deb && dpkg -i libssl-dev_1.0.1t-1+deb8u6_amd64.deb

# Install pg_pathman plguin
RUN wget https://github.com/postgrespro/pg_pathman/archive/1.3.tar.gz && tar -xzvf 1.3.tar.gz && cd pg_pathman-1.3/ && make install USE_PGXS=1

# Need SSH for cross connections
RUN mkdir /var/run/sshd && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Inherited variables
# ENV POSTGRES_PASSWORD monkey_pass
# ENV POSTGRES_USER monkey_user
# ENV POSTGRES_DB monkey_db

ENV CLUSTER_NAME pg_cluster

# special repmgr db for cluster info
ENV REPLICATION_DB replication_db
ENV REPLICATION_USER replication_user
ENV REPLICATION_PASSWORD replication_pass
ENV REPLICATION_PRIMARY_PORT 5432


# Host for replication (REQUIRED, NO DEFAULT)
# ENV REPLICATION_PRIMARY_HOST

# Integer number of node (REQUIRED, NO DEFAULT)
# ENV NODE_ID 1

# Node name (REQUIRED, NO DEFAULT)
# ENV NODE_NAME node1

# (default: hostname of the node)
# ENV CLUSTER_NODE_NETWORK_NAME pgmaster

# CLUSTER_NODE_NETWORK_NAME null
# (default: `hostname` of the node)

# ENV CONFIGS "listen_addresses:'*'"
                                    # in format variable1:value1[,variable2:value2[,...]]
                                    # used for pgpool.conf file

ENV ADAPTIVE_MODE 0
                    # This option(0|1) makes all nodes to be adaptive on RESTART only.
                    # So node decide to act as master or standby with connection to master

ENV MASTER_ROLE_LOCK_FILE_NAME $PGDATA/master.lock
                                                   # File will be put in $PGDATA/$MASTER_ROLE_LOCK_FILE_NAME when:
                                                   #    - node starts as a primary node/master
                                                   #    - node promoted to a primary node/master
                                                   # File does not exist
                                                   #    - if node starts as a standby

#### Advanced options ####
ENV CONNECT_TIMEOUT 2
ENV RECONNECT_ATTEMPTS 3
ENV RECONNECT_INTERVAL 5
ENV MASTER_RESPONSE_TIMEOUT 20
ENV LOG_LEVEL INFO
# Clean $PGDATA directory before start
ENV FORCE_CLEAN 0


COPY ./pgsql/bin /usr/local/bin/cluster
RUN chmod -R +x /usr/local/bin/cluster
RUN ln -s /usr/local/bin/cluster/functions/* /usr/local/bin/
COPY ./pgsql/configs /var/cluster_configs
COPY ./pgsql/ssh /home/postgres/.ssh

EXPOSE 22
EXPOSE 5432

VOLUME /var/lib/postgresql/data
USER root

CMD ["/usr/local/bin/cluster/entrypoint.sh"]
