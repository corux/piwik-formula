{% from "piwik/map.jinja" import piwik with context %}

include:
  - selinux

{% for file in [ piwik.directory + '/piwik/tmp(/.*)?', piwik.directory + '/piwik/misc(/.*)?', piwik.directory + '/piwik/plugins(/.*)?', piwik.config_file ] %}
piwik-selinux-{{ file }}:
  cmd.run:
    - name: "semanage fcontext -a -t httpd_sys_rw_content_t '{{ file }}'"
    - unless: "semanage fcontext --list | grep '{{ file }}' | grep httpd_sys_rw_content_t"
    - require:
      - cmd: piwik-install
    - watch_in:
      - module: piwik-selinux-restorecon
{% endfor %}

piwik-selinux-restorecon:
  module.wait:
    - name: file.restorecon
    - path: {{ piwik.directory }}
    - recursive: True
    - watch:
      - cmd: piwik-install
      - file: piwik-chmod-config
{%- if not piwik.enable_installer %}
      - file: piwik-config
{%- endif %}
