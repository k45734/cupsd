FROM alpine
#VERSION
RUN cat '/etc/os-release' && sleep 10
# CUPS GO
ENV PYTHONUNBUFFERED=1
RUN set -x \

# 1. 저장소 설정: 최신(latest)과 개발판(edge)을 명확히 구분하여 등록
RUN echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories && \
    echo "@edge-testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@edge-community https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# 2. 패키지 설치: 일반 패키지는 최신 안정판에서, 특정 패키지는 edge에서 가져옴
RUN apk update && apk add --no-cache \
    cups \
    cups-libs \
    cups-client \
    cups-filters \
    cups-dev \
    avahi \
    inotify-tools \
    rsync \
    tzdata \
    curl \
    py3-pycups \
    gutenprint \
    gutenprint-libs \
    ghostscript \
    epson-inkjet-printer-escpr \
    brlaser \
    # @태그를 붙여서 특정 저장소에서 가져오도록 명시
    cups-pdf@edge-testing \
    hplip@edge-community && \
    rm -rf /var/cache/apk/*
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
