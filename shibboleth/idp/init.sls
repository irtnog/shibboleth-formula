{% from "shibboleth/idp/map.jinja" import idp_settings with context %}

shibboleth_idp_prerequisites:
  pkg.installed:
    - pkgs: {{ idp_settings.packages|yaml }}

shibboleth_idp_prefix:
  file.recurse:
    - name: {{ idp_settings.prefix }}
    - source: salt://shibboleth/idp/files/prefix
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: {{ idp_settings.user }}
    - group: {{ idp_settings.group }}

shibboleth_idp_dist:
  archive.extracted:
    - if_missing: {{ idp_settings.prefix }}/dist/shibboleth-identity-provider-{{ idp_settings.version }}/
    - name: {{ idp_settings.prefix }}/dist
    - source: {{ idp_settings.master_site}}/{{ idp_settings.version }}/shibboleth-identity-provider-{{ idp_settings.version }}{{ idp_settings.suffix }}
    - source_hash: {{ idp_settings.source_hash[idp_settings.suffix] }}
    - archive_format: {{ "tar" if idp_settings.suffix == ".tar.gz" else "zip" }}
    - archive_user: {{ idp_settings.user }}
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
        - archive: shibboleth_idp_dist

shibboleth_idp_update_sealer_key:
  cron.present:
    - name: {{ idp_settings.prefix }}/bin/update-sealer-key
    - user: {{ idp_settings.user }}
    - minute: random
    - hour: random
    - comment: "Update the Shibboleth Identity Provider cookie encryption (sealer) key once per day."
    - require:
        - cmd: shibboleth_idp_install
