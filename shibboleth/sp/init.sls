{% from "shibboleth/sp/map.jinja" import shibsp_settings with context %}
{% set dirsep = '\\' if grains['os_family'] == 'Windows' else '/' %}

shibsp:
  pkg.installed:
    - pkgs: {{ shibsp_settings.packages|yaml }}

  group.present:
    - name: {{ shibsp_settings.group }}
    - system: True
    - require:
        - pkg: shibsp

  user.present:
    - name: {{ shibsp_settings.user }}
    - system: True
    - gid: {{ shibsp_settings.group }}
    - home: /nonexistent
    - password: '*'
    - shell: /usr/sbin/nologin
    - require:
        - pkg: shibsp
        - group: shibsp

  file.recurse:
    - name: {{ shibsp_settings.config_directory|yaml_encode }}
    - source: salt://shibboleth/sp/files/
    - template: jinja
    - user: root
    - group: {{ shibsp_settings.group }}
    - dir_mode: 751
    - file_mode: 640
    - require:
        - pkg: shibsp
        - group: shibsp
        - user: shibsp

  service.running:
    - names: {{ shibsp_settings.services|yaml }}
    - enable: True
    - watch:
        - pkg: shibsp
        - file: shibsp

{% for mp in shibsp_settings.metadata_providers if mp is mapping %}
{% for filter in mp.metadata_filters|default([]) if filter.type == 'Signature' %}
{% set hash = salt['hashutil.digest'](mp.url) %}
shibsp_{{ hash }}_signing_certificate:
  file.managed:
    - name: {{ '%s%s_%s.pem'|format(shibsp_settings.config_directory, dirsep, hash)|yaml_encode }}
    - contents: {{ filter.certificate|yaml_encode }}
    - user: root
    - group: {{ shibsp_settings.group }}
    - dir_mode: 751
    - file_mode: 640
    - require:
        - file: shibsp
    - watch_in:
        - service: shibsp
{% endfor %}
{% endfor %}
