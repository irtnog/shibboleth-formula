{% from "shib/idp/map.jinja" import shibidp_settings with context %}

shibidp:
  pkg.installed:
    - pkgs: {{ shibidp_settings.packages|yaml }}
  file.recurse:
    - name: {{ shibidp_settings.prefix }}
    - source: salt://shibboleth/idp/files/prefix
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - dir_mode: 750
    - file_mode: 640
  archive.extracted:
    - if_missing: {{ shibidp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ shibidp_settings.version }}/
    - name: {{ shibidp_settings.prefix }}/vendor
    - source: {{ shibidp_settings.master_site}}/{{ shibidp_settings.version }}/shibboleth-identity-provider-{{ shibidp_settings.version }}{{ shibidp_settings.suffix }}
    - source_hash: {{ shibidp_settings.source_hash[shibidp_settings.suffix] }}
    - archive_format: {{ "tar" if shibidp_settings.suffix == ".tar.gz" else "zip" }}
    - archive_user: {{ shibidp_settings.user }}
    - tar_options: v            # force use of tar(1) instead of tarfile.py
    - keep: yes
    - require:
        - file: shibidp
  cmd.wait_script:
    - source: salt://shibboleth/idp/files/install.sh
    - template: jinja
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - watch:
        - pkg: shibidp
        - file: shibidp
        - archive: shibidp
  cron.present:
    - name: /bin/sh {{ shibidp_settings.prefix }}/bin/update-sealer-key.sh
    - user: {{ shibidp_settings.user }}
    - minute: random
    - hour: random
    - comment: "Update the Shibboleth Identity Provider cookie encryption (sealer) key once per day."
    - require:
        - cmd: shibidp

## In order to have the installation script generate any missing
## configuration files, it is necessary to also let it generate its
## own keying material.  This state overwrites that keying material
## with the official key pairs stored in Pillar.
shibidp_keymat:
  file.recurse:
    - name: {{ shibidp_settings.prefix }}
    - source: salt://shibboleth/idp/files/keymat
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - dir_mode: 750
    - file_mode: 640
    - require:
        - cmd: shibidp

## The vendor hardcodes shell scripts to use /bin/bash, which doesn't
## exist in that location on all operating systems.  When necessary,
## this symlink gets created as a workaround.
{% if grains['os_family'] == 'FreeBSD' %}
shibidp_bash_symlink:
  file.symlink:
    - name: /bin/bash
    - target: /usr/local/bin/bash
    - require:
        - pkg: shibidp
    - require_in:
        - cmd: shibidp
        - cron: shibidp
{% endif %}
