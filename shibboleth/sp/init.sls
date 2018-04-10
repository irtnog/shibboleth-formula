{%- from "shibboleth/sp/map.jinja" import shibsp_settings with context %}
{%- from "shibboleth/sp/lib.jinja" import generate_sp_keymat_states, generate_sp_metadata_signing_cert_states, generate_sp_inline_metadata_states with context %}
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

## Handle SP keying material.
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
{{  generate_sp_metadata_signing_cert_states(
      app_overrides=shibsp_settings.app_overrides,
      confdir=shibsp_settings.confdir,
      dirsep=dirsep,
      group=shibsp_settings.group,
      metadata_providers=shibsp_settings.metadata_providers,
    ) }}

## Handle inline metadata.
{{  generate_sp_inline_metadata_states(
      app_overrides=shibsp_settings.app_overrides,
      confdir=shibsp_settings.confdir,
      dirsep=dirsep,
      group=shibsp_settings.group,
      metadata_providers=shibsp_settings.metadata_providers,
    ) }}

## Handle per-application attribute maps.
{{  generate_sp_attribute_map_states(
      app_overrides=shibsp_settings.app_overrides,
      confdir=shibsp_settings.confdir,
      dirsep=dirsep,
      user=shibsp_settings.user,
      group=shibsp_settings.group,
    ) }}

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
