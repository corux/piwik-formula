{% from 'piwik/map.jinja' import piwik with context %}
{% from 'selinux/map.jinja' import selinux with context %}

include:
  - epel
  - php.ng
  - php.ng.gd
  - php.ng.cli
  - php.ng.xml
  - php.ng.mysql
  - php.ng.mbstring
{% if selinux.enabled %}
  - .selinux
{% endif %}

piwik-pkgs:
  pkg.installed:
    - pkgs:
      - crudini

piwik-dir:
  file.directory:
    - name: {{ piwik.directory }}
    - user: root
    - group: root
    - mode: 755

piwik-version:
{% if piwik.version|lower == 'latest' %}
  cmd.run:
    - name: curl {{ piwik.latest_url }} --silent -o {{ piwik.directory }}/version
    - unless: test -f {{ piwik.directory }}/version && test "x`curl {{ piwik.latest_url }} --silent`" = "x`cat {{ piwik.directory }}/version`"
{% else %}
  file.managed:
    - name: {{ piwik.directory }}/version
    - user: root
    - group: root
    - mode: 644
    - contents: {{ piwik.version }}
{% endif %}
    - require:
      - file: piwik-dir
    - require_in:
      - cmd: piwik-install
    - watch_in:
      - cmd: piwik-maintenance-start

piwik-install:
  cmd.wait:
    - name: curl "{{ piwik.builds }}/piwik-`cat {{ piwik.directory }}/version`.tar.gz" -L --silent | tar -xz && chown root:root -R {{ piwik.directory }}
    - cwd: {{ piwik.directory }}
    - watch:
      - cmd: piwik-maintenance-start

piwik-chmod-dirs:
  file.directory:
    - names:
      - {{ piwik.directory }}/piwik/tmp
      - {{ piwik.directory }}/piwik/misc
      - {{ piwik.directory }}/piwik/plugins
{% if piwik.enable_installer %}
      - {{ piwik.directory }}/piwik/config
{% endif %}
    - user: apache
    - group: apache
    - mode: 750
    - recurse:
      - user
      - group
    - require:
      - cmd: piwik-install

piwik-maintenance-start:
  cmd.wait:
    - name: 'test ! -f {{ piwik.config_file }} || ( crudini --set "{{ piwik.config_file }}" General maintenance_mode 1 && crudini --set "{{ piwik.config_file }}" Tracker record_statistics 0 )'
    - require:
      - pkg: piwik-pkgs

piwik-maintenance-update-schema:
  cmd.wait:
    - name: test ! -f {{ piwik.config_file }} || php {{ piwik.console }} core:update --yes
    - user: apache
    - cwd: {{ piwik.directory }}
    - watch:
      - cmd: piwik-install
    - require:
      - pkg: piwik-pkgs

piwik-maintenance-end:
  cmd.run:
    - name: 'crudini --del "{{ piwik.config_file }}" General maintenance_mode; crudini --del "{{ piwik.config_file }}" Tracker record_statistics'
    - onlyif: 'crudini --get "{{ piwik.config_file }}" General maintenance_mode || crudini --get "{{ piwik.config_file }}" Tracker record_statistics'
    - watch:
      - cmd: piwik-maintenance-update-schema
    - require:
      - pkg: piwik-pkgs

{# when using the installer, the config file will be managed by Piwik #}
{% if not piwik.enable_installer %}
piwik-chmod-config:
  file.managed:
    - name: {{ piwik.config_file }}
    - user: apache
    - group: apache
    - mode: 600
    - require:
      - cmd: piwik-install

piwik-config:
  file.managed:
    - name: {{ piwik.config_file }}
    - source: salt://piwik/files/config.ini.php
    - template: jinja
    - defaults:
        config: {{ piwik.get('config', {})|yaml }}
    - require_in:
      - cmd: piwik-maintenance-update-schema
      - cmd: piwik-maintenance-end
{% endif %}

piwik-cronjob-log:
  cmd.run:
    - name: touch {{ piwik.logfile }}
    - unless: test -f {{ piwik.logfile }}

  file.managed:
    - name: {{ piwik.logfile }}
    - user: apache
    - group: apache
    - mode: 644
    - require:
      - cmd: piwik-cronjob-log

piwik-cronjob:
  file.managed:
    - name: /etc/cron.hourly/0piwik
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/sh
        su -s /bin/sh apache -c '/usr/bin/php {{ piwik.console }} core:archive --url={{ piwik.url }} >> {{ piwik.logfile }}'

geoip:
  pkg.installed:
    - pkgs:
      - php-pecl-geoip
      - GeoIP

  file.symlink:
    - name: /usr/share/GeoIP/GeoIPCity.dat
    - target: GeoLiteCity.dat
    - require:
      - pkg: geoip

geoip-update-cronjob:
  file.managed:
    - name: /etc/cron.daily/0geoip
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/sh
        /usr/bin/geoipupdate
