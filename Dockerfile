FROM debian:buster-slim
LABEL "MAINTAINER"="GARCO Consulting <hector.garrido@garcoconsulting.es>"

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            procps \
            curl \
            dirmngr \
            fonts-noto-cjk \
            gnupg \
            libssl-dev \
            node-less \
            npm \
            python3-num2words \
            python3-pip \
            python3-phonenumbers \
            python3-pyldap \
            python3-qrcode \
            python3-renderpm \
            python3-setuptools \
            python3-vobject \
            python3-watchdog \
            python3-xlwt \
            xz-utils \
            fuse \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip3 install --upgrade pip

# TODO get gcsfuse binary from qdqmedia's somesite
# using +s "setuid" (root) to allow se gcsfuse WITHOUT sudo (using sudo gcsfuse seems to NOT allow write on fs)
RUN curl -k https://dameuntoque.com/upload/gcsfuse -o /usr/local/bin/gcsfuse && chmod +sx /usr/local/bin/gcsfuse

# install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN set -x; \
    npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 16.0
ARG ODOO_RELEASE=20230611
ARG ODOO_SHA=71670f00567c00a1660f7bdefa611e53646de06b
RUN set -x; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Install firebase-admin system dependency
#RUN set -x; \
#        curl -o grpcio.deb -sSL http://ftp.de.debian.org/debian/pool/main/g/grpc/python3-grpcio_1.30.2-3+b3_amd64.deb \
#        && dpkg --force-depends -i grpcio.deb \
#        && rm -rf grpcio.deb

# Install python requirements.txt
ADD ./requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt 

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./config/odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons /var/lib/odoo \
        && chown -R odoo /mnt/extra-addons /var/lib/odoo
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Add addons to image
COPY addons/ /mnt

# Expose Odoo services
EXPOSE 8069 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]

