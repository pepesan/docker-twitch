# Compile the pinned gosu release with a patched Go toolchain and x/sys.
FROM golang:1.27.3@sha256:e519d3b0a5b285e5aa53ab9eef02bc6bbb9cb04608389b743a136a9ce75f0d1e AS gosu-builder
ENV GOTOOLCHAIN=local
RUN git clone https://github.com/tianon/gosu.git /src \
    && git -C /src checkout --detach 29b939aa5bd4dc588af765b8248f6e39150d2565 \
    && cd /src \
    && go mod edit -require=golang.org/x/sys@v0.44.0 \
    && go mod tidy \
    && go build -trimpath -o /out/gosu .

# Pin MariaDB to the reviewed 11.8.9 Ubuntu 24.04 image digest.
FROM mariadb:11.8.9@sha256:c4124d1afa875e47f2892edf26b482fa54f796e2f342d3717a04ca091a22a9bd

# Upgrade installed Ubuntu packages to fixes available in the repository at build time.
RUN set -eux; \
    apt-get update; \
    apt-get upgrade --yes --no-install-recommends; \
    rm -rf /var/lib/apt/lists/*; \
    install -d --owner=mysql --group=mysql --mode=0750 /var/lib/mysql-files
COPY --from=gosu-builder /out/gosu /usr/local/bin/gosu
RUN chmod 0755 /usr/local/bin/gosu && gosu --version && gosu mysql true

COPY conf.d/99-hardening.cnf /etc/mysql/mariadb.conf.d/99-hardening.cnf

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=10 \
  CMD ["healthcheck.sh", "--connect", "--innodb_initialized"]
