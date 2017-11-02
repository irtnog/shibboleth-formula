{%- from "shibboleth/sp/map.jinja" import shibsp_settings with context %}
{%- from "shibboleth/sp/lib.jinja" import generate_sp_keymat_states with context %}
{%- set dirsep = '\\' if grains['os_family'] == 'Windows' else '/' %}

shibsp:
  pkg.installed:
    - pkgs: {{ shibsp_settings.packages|yaml }}

  group.present:
    - name: {{ shibsp_settings.group|yaml_encode }}
    - system: True
    - addusers:
        - {{ shibsp_settings.mod_shib_user|yaml_encode }}
    - require:
        - pkg: shibsp

  user.present:
    - name: {{ shibsp_settings.user|yaml_encode }}
    - system: True
    - gid: {{ shibsp_settings.group|yaml_encode }}
    - home: /var/run/shibboleth
    - createhome: False
    - password: '*'
    - shell: /usr/sbin/nologin
    - require:
        - pkg: shibsp
        - group: shibsp

  file.recurse:
    - name: {{ shibsp_settings.confdir|yaml_encode }}
    - source: salt://shibboleth/sp/files/
    - template: jinja
    - include_empty: yes
    - exclude_pat: E@(\.gitignore|sp-(encryption|signing).(crt|key))
    - user: {{ shibsp_settings.user|yaml_encode }}
    - group: {{ shibsp_settings.group|yaml_encode }}
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

## Handle optional SP keying material.
{{ generate_sp_keymat_states(
     app_overrides=shibsp_settings.app_overrides,
     confdir=shibsp_settings.confdir,
     dirsep=dirsep,
     encryption_certificate=shibsp_settings.encryption_certificate,
     encryption_key=shibsp_settings.encryption_key,
     group=shibsp_settings.group,
     signing_certificate=shibsp_settings.signing_certificate,
     signing_key=shibsp_settings.signing_key,
     user=shibsp_settings.user,
   ) }}

## Handle inline metadata signing certificates.
{%- for mp in shibsp_settings.metadata_providers if mp is mapping %}
{%-   for filter in mp.metadata_filters|default([]) if filter.type == 'Signature' %}
{%-     set hash = salt['hashutil.digest'](mp.url) %}
shibsp_{{ hash }}_signing_certificate:
  file.managed:
    - name: {{ '%s%s_%s.pem'|format(shibsp_settings.confdir, dirsep, hash)|yaml_encode }}
    - contents: {{ filter.certificate|yaml_encode }}
    - user: root
    - group: {{ shibsp_settings.group|yaml_encode }}
    - dir_mode: 751
    - file_mode: 640
    - require:
        - file: shibsp
    - watch_in:
        - service: shibsp
{%-   endfor %}
{%- endfor %}

## Handle inline metadata.
{%- for mp in shibsp_settings.metadata_providers if mp is string and not mp.startswith('http') %}
{%-   set hash = salt['hashutil.digest'](mp) %}
shibsp_inline_metadata_{{ loop.index0 }}:
  file.managed:
    - name: {{ '%s%s_%s.xml'|format(shibsp_settings.confdir, dirsep, hash)|yaml_encode }}
    - contents: {{ mp|yaml_encode }}
    - user: {{ shibsp_settings.user|yaml_encode }}
    - group: {{ shibsp_settings.group|yaml_encode }}
    - file_mode: 640
    - require:
        - file: shibsp
    - watch_in:
        - service: shibsp
{%- endfor %}

## Work around bug in the Shibboleth SELinux policy module that
## prevents httpd/mod_shib from communicating with shibd.
{%- if grains['os_family'] in [
      'RedHat',
    ] %}
shibsp_selinux:
  cmd.wait:
    - name:
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/run/shibboleth(/.)?" &&
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/cache/shibboleth(/.)?" &&
        restorecon -R -v /var/run/shibboleth &&
        restorecon -R -v /var/cache/shibboleth
    - watch:
        - pkg: shibsp
    - require_in:
        - service: shibsp
{%- endif %}
