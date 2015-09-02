{% from "shibboleth/idp/map.jinja" import idp_settings with context %}

shibboleth_idp_prerequisites:
  pkg.installed:
    - pkgs: {{ idp_settings.packages|yaml }}

{% if grains['os_family'] == 'FreeBSD' %}
shibboleth_idp_bash_symlink:
  file.symlink:
    - name: /bin/bash
    - target: /usr/local/bin/bash
    - require:
        - pkg: shibboleth_idp_prerequisites
    - require_in:
        - cmd: shibboleth_idp_install
        - cron: shibboleth_idp_update_sealer_key
{% endif %}

shibboleth_idp_prefix:
  file.recurse:
    - name: {{ idp_settings.prefix }}
    - source: salt://shibboleth/idp/files/prefix
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}

shibboleth_idp_vendor:
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
        - file: shibboleth_idp_prefix

shibboleth_idp_install:
  cmd.wait_script:
    - source: salt://shibboleth/idp/files/install.sh
    - template: jinja
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}
    - require:
        - pkg: shibboleth_idp_prerequisites
    - watch:
        - file: shibboleth_idp_prefix
        - archive: shibboleth_idp_vendor

shibboleth_idp_update_sealer_key:
  cron.present:
    - name: /bin/sh {{ idp_settings.prefix }}/bin/update-sealer-key.sh
    - user: {{ idp_settings.user }}
    - minute: random
    - hour: random
    - comment: "Update the Shibboleth Identity Provider cookie encryption (sealer) key once per day."
    - require:
        - cmd: shibboleth_idp_install
