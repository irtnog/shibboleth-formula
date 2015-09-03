{% from "shibboleth/idp/map.jinja" import idp_settings with context %}

shibboleth_idp:
  pkg.installed:
    - pkgs: {{ idp_settings.packages|yaml }}
  file.recurse:
    - name: {{ idp_settings.prefix }}
    - source: salt://shibboleth/idp/files/prefix
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}
    - dir_mode: 750
    - file_mode: 640
  archive.extracted:
    - if_missing: {{ idp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ idp_settings.version }}/
    - name: {{ idp_settings.prefix }}/vendor
    - source: {{ idp_settings.master_site}}/{{ idp_settings.version }}/shibboleth-identity-provider-{{ idp_settings.version }}{{ idp_settings.suffix }}
    - source_hash: {{ idp_settings.source_hash[idp_settings.suffix] }}
    - archive_format: {{ "tar" if idp_settings.suffix == ".tar.gz" else "zip" }}
    - archive_user: {{ idp_settings.user }}
    - tar_options: v            # force use of tar(1) instead of tarfile.py
    - keep: yes
    - require:
        - file: shibboleth_idp
  cmd.wait_script:
    - source: salt://shibboleth/idp/files/install.sh
    - template: jinja
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}
    - watch:
        - pkg: shibboleth_idp
        - file: shibboleth_idp
        - archive: shibboleth_idp
  cron.present:
    - name: /bin/sh {{ idp_settings.prefix }}/bin/update-sealer-key.sh
    - user: {{ idp_settings.user }}
    - minute: random
    - hour: random
    - comment: "Update the Shibboleth Identity Provider cookie encryption (sealer) key once per day."
    - require:
        - cmd: shibboleth_idp

## In order to have the installation script generate any missing
## configuration files, it is necessary to also let it generate its
## own keying material.  This state overwrites that keying material
## with the official key pairs stored in Pillar.
shibboleth_idp_keymat:
  file.recurse:
    - name: {{ idp_settings.prefix }}
    - source: salt://shibboleth/idp/files/keymat
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}
    - dir_mode: 750
    - file_mode: 640
    - require:
        - cmd: shibboleth_idp_install

## The vendor hardcodes shell scripts to use /bin/bash, which doesn't
## exist in that location on all operating systems.  When necessary,
## this symlink gets created as a workaround.
{% if grains['os_family'] == 'FreeBSD' %}
shibboleth_idp_bash_symlink:
  file.symlink:
    - name: /bin/bash
    - target: /usr/local/bin/bash
    - require:
        - pkg: shibboleth_idp
    - require_in:
        - cmd: shibboleth_idp
        - cron: shibboleth_idp
{% endif %}
