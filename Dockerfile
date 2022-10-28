FROM debian:bullseye-slim

ENV SSH_USERPASS temp_pass
ENV REPREPRO_BASE_DIR /repo
ENV REPREPRO_CONFIG_DIR /conf
ENV INCOMING_DIR /incoming
ENV GNUPGHOME /gnupg
ENV KEYS_DIR /keys

# Install supervisor for managing services
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
                                        supervisor \
                                        cron \
                                        openssh-server \
                                        pwgen \
                                        reprepro \
                                        screen \
                                        vim-tiny \
                                        nginx \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/*

# Configure cron
# Install cron for managing regular tasks
RUN sed -i 's/\(session *required *pam_loginuid.so\)/#\1/' /etc/pam.d/cron

# Install ssh (run/stop to create required directories)
RUN mkdir -p /var/run/sshd
# RUN service ssh start ; sleep 1
# RUN service ssh stop

# Configure reprepro
COPY scripts/reprepro-import.sh /usr/local/sbin/reprepro-import
RUN chmod 755 /usr/local/sbin/reprepro-import
            # && mkdir -p /var/lib/reprepro/conf

COPY $REPREPRO_CONFIG_DIR $REPREPRO_CONFIG_DIR

# Configure nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
    && rm -f /etc/nginx/sites-enabled/default

COPY configs/nginx-default.conf /etc/nginx/sites-enabled/default

# Setup root access
RUN echo "root:docker" | chpasswd

# Configure supervisor
# RUN service supervisor stop

COPY configs/supervisor/ /etc/supervisor/conf.d/

# Finalize
ENV DEBIAN_FRONTEND newt

COPY scripts/start.sh /usr/local/sbin/start
RUN chmod 755 /usr/local/sbin/start

VOLUME [$KEYS_DIR, $REPREPRO_BASE_DIR, $GNUPGHOME, $REPREPRO_CONFIG_DIR, $INCOMING_DIR]

EXPOSE 80
EXPOSE 22
CMD ["/usr/local/sbin/start"]
