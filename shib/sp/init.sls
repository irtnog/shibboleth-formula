{% from "shib/sp/map.jinja" import shibsp_settings with context %}

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
    - name: {{ shibsp_settings.config_directory }}
    - source: salt://shib/sp/files/
    - template: jinja
    - user: root
    - group: {{ shibsp_settings.group }}
    - dir_mode: 751
    - file_mode: 640
    - require:
        - pkg: shibsp
        - group: shibsp
        - user: shibsp
