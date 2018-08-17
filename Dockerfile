FROM alpine:3.8

ENV UID_MIN "10001"

# USERS: Format username:[password]:[disabled]
ENV USERS ""

# HOST_PRIV_KEY_RSA: RSA Private Key - optional
ENV HOST_PRIV_KEY_RSA ""

# HOST_PRIV_KEY_ED25519: Host ED25519 Private Key - optional
ENV HOST_PRIV_KEY_ED25519 ""

# USER_KEYS_BASE: Public Keys added to all accounts
ENV USER_KEYS_BASE ""

# USER_KEYS_DEFAULT: Public Keys added to accounts that don't have user-specific keys
ENV USER_KEYS_DEFAULT ""

# USER_KEYS_username: Public Keys added to the specified account username
# USER_KEYS_username ""

# USER_DIRS_BASE: Sub-Directories created for all (new) accounts
ENV USER_DIRS_BASE ""

# USER_DIRS_DEFAULT: Sub-Directories created for accounts that don't have user-specific directories set
ENV USER_DIRS_DEFAULT ""

# USER_DIRS_username: Sub-Directories created for the specified account username
# USER_DIRS_username: ""

RUN addgroup -g 10000 sftpuser && \
    mkdir -p /data && \
    chmod 710 /data && \
    chown root.sftpuser /data

RUN apk add -U openssh 

COPY files/ /

VOLUME [ "/data" ]

EXPOSE 22
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/usr/sbin/sshd","-D", "-e"]
