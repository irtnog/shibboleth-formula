{% from "shibboleth/idp/map.jinja" import shibidp_settings with context %}

shibidp:
  pkg.installed:
    - pkgs: {{ shibidp_settings.packages|yaml }}

  file.recurse:
    - name: {{ shibidp_settings.prefix }}
    - source: salt://shibboleth/idp/files
    - template: jinja
    - include_empty: yes
    - exclude_pat: E@\.gitignore
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
    - source: salt://shibboleth/idp/scripts/install.sh
    - template: jinja
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - watch:
        - pkg: shibidp
        - archive: shibidp

  cron.present:
    - identifier: shibidp_update_sealer_key
    - name: /bin/sh {{ shibidp_settings.prefix }}/bin/update-sealer-key.sh
    - user: {{ shibidp_settings.user }}
    - minute: random
    - hour: random
    - comment: "Update the Shibboleth Identity Provider data sealer key once per day."
    - require:
        - cmd: shibidp

## In order to have the installation script generate any missing
## configuration files, it is necessary to also let it generate its
## own keying material.  These states overwrites the
## installer-generated keymat with the real keymat stored in Pillar.
shibidp_keymat:
  file.recurse:
    - name: {{ shibidp_settings.prefix }}/credentials
    - source: salt://shibboleth/idp/keymat
    - template: jinja
    - include_empty: yes
    - exclude_pat: E@\.gitignore
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - dir_mode: 750
    - file_mode: 640
    - require:
        - cmd: shibidp

  ## Re-generate the PKCS#12 container that holds the back channel key
  ## pair.  Note that the password used to encrypt the container gets
  ## passed via an environment variable in order to prevent it leaking
  ## via the process list.
  cmd.wait:
    - name:
        openssl pkcs12 -export -password env:SHIBIDP_KEYSTORE_PASSWORD
          -out   {{ shibidp_settings.prefix }}/credentials/idp-backchannel.p12
          -in    {{ shibidp_settings.prefix }}/credentials/idp-backchannel.crt
          -inkey {{ shibidp_settings.prefix }}/credentials/idp-backchannel.key
    - env:
        - SHIBIDP_KEYSTORE_PASSWORD:
            {{ shibidp_settings.keystore_password|yaml_encode }}
    - runas: {{ shibidp_settings.user }}
    - watch:
        - file: shibidp_keymat

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

## Handle inline metadata.
{% for mp in shibidp_settings.metadata_providers
   if mp is string and not mp.startswith('http') %}
{% set mp_id = salt['hashutil.digest'](mp) %}
shibidp_inline_metadata_{{ loop.index0 }}:
  file.managed:
    - name: {{ shibidp_settings.prefix }}/metadata/{{ mp_id }}.xml
    - contents: {{ mp|yaml_encode }}
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - file_mode: 640            # FIXME: too strict?
    - require:
        - file: shibidp
{% endfor %}
