{% from "piwik/map.jinja" import piwik with context %}

include:
  - apache

piwik-apache:
  file.managed:
    - name: /etc/httpd/conf.d/piwik.conf
    - source: salt://piwik/files/piwik-apache.conf
    - template: jinja
    - defaults:
        config: {{ piwik }}
    - watch_in:
      - module: apache-reload
