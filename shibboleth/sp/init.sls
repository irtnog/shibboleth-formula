{% from "shibboleth/sp/map.jinja" import shibsp_settings with context %}
{% set dirsep = '\\' if grains['os_family'] == 'Windows' else '/' %}
{% set repo_url = 'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_%s'|format(grains['osmajorrelease']) if grains['os'] in ['CentOS', 'RedHat'] and grains['osmajorrelease'] >= 7 else
                  'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_CentOS-6' if grains['os'] == 'CentOS' and grains['osmajorrelease'] == 6 else
                  'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_5' if grains['os'] == 'CentOS' and grains['osmajorrelease'] == 5 else
                  'http://download.opensuse.org/repositories/security:/shibboleth/RHEL_%s'|format(grains['osmajorrelease']) if grains['os'] == 'RedHat' and grains['osmajorrelease'] <= 6 else
                  'http://download.opensuse.org/repositories/security:/shibboleth/SLE_%s'|format(grains['osrelease'].replace(' ', '_')) if grains['os'] == 'SUSE' else
                  'http://download.opensuse.org/repositories/security:/shibboleth/openSUSE_%s'|format(grains['osrelease'].replace(' ', '_')) if grains['os'] == 'openSUSE' else
                  False %}

shibsp:
{% if repo_url %}
  pkgrepo.managed:
    - name: security_shibboleth
    - humanname: Shibboleth ({{ '%s_%s'|format(grains['os'], grains['osmajorrelease']) }})
    - baseurl: {{ repo_url|yaml_encode }}
    - gpgkey: {{'%s/repodata/repomd.xml.key'|format(repo_url)|yaml_encode }}
    - gpgcheck: 1
    - require_in:               # use require_in to force repo update
        - pkg: shibsp
{% endif %}

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
        - file: shibsp_keymat

shibsp_keymat:
  file.recurse:
    - name: {{ shibsp_settings.config_directory|yaml_encode }}
    - source: salt://shibboleth/sp/keymat
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ shibsp_settings.user }}
    - group: {{ shibsp_settings.group }}
    - dir_mode: 750
    - file_mode: 600
    - require:
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


{% if grains['os_family'] in ['RedHat'] %}
## Work around bug in the Shibboleth SELinux policy module that
## prevents httpd/mod_shib from communicating with shibd.
shibsp_selinux_socket:
  cmd.wait:
    - name:
        semanage fcontext -a -t httpd_sys_rw_content_t /var/run/shibboleth
    - watch:
        - pkg: shibsp
    - require_in:
        - service: shibsp
{% endif %}
