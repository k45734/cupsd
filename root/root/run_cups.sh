#!/bin/sh
set -ex

# SANED SETTING - 에러 방지를 위해 주석 처리
# [수정] 아래 디렉토리가 존재하지 않아 발생하는 에러를 막기 위해 주석 처리함
# echo "data_portrange = ${DATA_PORT_RANGE}" > /etc/sane.d/saned.conf

# for HOST in ${ALLOW_HOSTS}; do
#   echo $HOST >> /etc/sane.d/saned.conf
# done

# Is CUPSADMIN set? If not, set to default
if [ -z "$CUPSADMIN" ]; then
    CUPSADMIN="cupsadmin"
fi

# Is CUPSPASSWORD set? If not, set to $CUPSADMIN
if [ -z "$CUPSPASSWORD" ]; then
    CUPSPASSWORD=$CUPSADMIN
fi

if [ $(grep -ci $CUPSADMIN /etc/shadow) -eq 0 ]; then
    # lpadmin 그룹이 없는 환경에서도 안전하게 실행되도록 처리
    adduser -S -G lpadmin --no-create-home $CUPSADMIN || adduser -S --no-create-home $CUPSADMIN 
fi
echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

mkdir -p /config/ppd
mkdir -p /services
rm -rf /etc/avahi/services/*
rm -rf /etc/cups/ppd
ln -s /config/ppd /etc/cups

if [ `ls -l /services/*.service 2>/dev/null | wc -l` -gt 0 ]; then
	cp -f /services/*.service /etc/avahi/services/
fi

if [ `ls -l /config/printers.conf 2>/dev/null | wc -l` -eq 0 ]; then
    touch /config/printers.conf
fi
cp /config/printers.conf /etc/cups/printers.conf

# 서비스 실행
/usr/sbin/avahi-daemon --daemonize
/root/printer-update.sh &

# [수정] 스캔 서버 실행 부분 주석 처리
# inetd -f -e & 

exec /usr/sbin/cupsd -f