#!/usr/bin/env python3

import time
import os

print("Start")

os.system("ufw allow 8080")
os.system("/opt/tomcat/bin/startup.sh")

os.system("java \
    -Djava.util.logging.config.file=/opengrok/etc/logging.properties \
    -jar /opengrok/dist/lib/opengrok.jar \
    -c /usr/local/bin/ctags \
    -s /opengrok/src -d /opengrok/data -H -P -S -G \
    -W /opengrok/etc/configuration.xml -U http://localhost:8080/source \
    -R /opengrok/etc/readonly-configuration.xml \
")

while True:
    time.sleep(10)