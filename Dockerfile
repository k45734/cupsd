FROM alpine
#VERSION
RUN cat '/etc/os-release' && sleep 10
# CUPS GO
ENV PYTHONUNBUFFERED=1
RUN set -x \

RUN echo "**** install Python ****" && \
    apk add --update --no-cache python3-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    echo "**** install pip ****" && \
    python3 -m venv --system-site-packages /usr/local && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    echo "**** install cron ****" && \
    #echo -e "http://nl.alpinelinux.org/alpine/edge/testing\nhttp://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories &&\
    apk add --update --no-cache cups \
    cups-libs \
    #cups-pdf \
    cups-client \
    cups-filters \
    cups-dev \
    gutenprint \
    gutenprint-libs \
    gutenprint-doc \
    gutenprint-cups \
    ghostscript \
    epson-inkjet-printer-escpr \
    brlaser  \
    #hplip  \
    avahi \
    inotify-tools \
    rsync \
    tzdata \
    curl \
    py3-pycups \
    ##&& apk add hplip --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    && rm -rf /var/cache/apk/*
RUN apk add --update --no-cache cups-pdf --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN apk add --update --no-cache hplip --repository=https://dl-cdn.alpinelinux.org/alpine/v3.20/community
#TIMEZONE
ENV TZ Asia/Seoul

#LANG
ENV LANG ko_KR.UTF-8
ENV LANGUAGE ko_KR.UTF-8
ENV LC_ALL ko_KR.UTF-8

# This will use port 2631 CUPS
EXPOSE 2631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
#CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 2631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

#SANED SEVER SCAN
#RUN apk add --update --no-cache bash sane-saned sane-utils sane-backend-epson sane-backend-epson2 busybox-extras && \
#    echo "6566 stream tcp nowait root.root /usr/sbin/saned saned" >/etc/inetd.conf && \
#    addgroup saned lp

#ADD https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework /pipework

# This will use port 6566-6570 SANE scanner
#EXPOSE 6566-6570

#ENV DATA_PORT_RANGE="6567-6570" ALLOW_HOSTS="192.168.0.0/24 172.17.0.1/24"
#RUN sed -i 's/providers = provider_sect/ssl_conf = ssl_sect/' /etc/ssl/openssl.cnf  && \
#    sed -i'' -r -e "/ssl_conf = ssl_sect/a\[ssl_sect]" /etc/ssl/openssl.cnf  && \
#    sed -i'' -r -e "/\[ssl_sect\]/a\system_default = system_default_sect" /etc/ssl/openssl.cnf  && \
#    sed -i'' -r -e "/system_default = system_default_sect/a\[system_default_sect]" /etc/ssl/openssl.cnf  && \
#    sed -i'' -r -e "/\[system_default_sect\]/a\Options = UnsafeLegacyRenegotiation" /etc/ssl/openssl.cnf  && \
#    echo "ssl edit ok"
HEALTHCHECK --interval=10s --timeout=3s CMD curl -f http://www.google.com || exit 1
#LAST
CMD ["/root/run_cups.sh"]
