#### SHIBBOLETH/IDP/INIT.SLS --- Salt states managing the Shibboleth IdP

### Copyright (c) 2015, Matthew X. Economou <xenophon@irtnog.org>
###
### Permission to use, copy, modify, and/or distribute this software
### for any purpose with or without fee is hereby granted, provided
### that the above copyright notice and this permission notice appear
### in all copies.
###
### THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
### WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
### WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
### AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
### CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
### LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
### NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
### CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

### This file installs and configures the OpenSSH server.  The key
### words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
### "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in
### this document are to be interpreted as described in RFC 2119,
### https://tools.ietf.org/html/rfc2119.  The key words "MUST (BUT WE
### KNOW YOU WON'T)", "SHOULD CONSIDER", "REALLY SHOULD NOT", "OUGHT
### TO", "WOULD PROBABLY", "MAY WISH TO", "COULD", "POSSIBLE", and
### "MIGHT" in this document are to be interpreted as described in RFC
### 6919, https://tools.ietf.org/html/rfc6919.  The keywords "DANGER",
### "WARNING", and "CAUTION" in this document are to be interpreted as
### described in OSHA 1910.145,
### https://www.osha.gov/pls/oshaweb/owadisp.show_document?p_table=standards&p_id=9794.

{%- from "shibboleth/idp/map.jinja" import shibidp_settings with context %}

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
    - name: {{ shibidp_settings.prefix }}/vendor
    - source: {{ shibidp_settings.master_site}}/{{ shibidp_settings.version }}/shibboleth-identity-provider-{{ shibidp_settings.version }}{{ shibidp_settings.suffix }}
    - source_hash: {{ shibidp_settings.source_hash[shibidp_settings.suffix] }}
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - keep: yes
    - require:
        - file: shibidp

  cmd.script:
    - source: salt://shibboleth/idp/scripts/install.sh
    - template: jinja
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - require:
        - pkg: shibidp
    - onchanges:
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

  ## Generate the PKCS#12 container, used in Jetty deployments, that
  ## holds the back channel key pair.  Note that the password used to
  ## encrypt the container gets passed via an environment variable in
  ## order to prevent it leaking via the process list.  This formula
  ## cannot detect keystore password changes as a result.  To cause it
  ## to regenerate the PKCS#12 container, add an `onchanges_in`
  ## requisite referencing `cmd: shibidp_keymat` to whatever state
  ## manages the Jetty configuration file containing the keystore
  ## password.
  cmd.run:
    - name:
        openssl pkcs12 -export -password env:SHIBIDP_KEYSTORE_PASSWORD
          -out   {{ shibidp_settings.prefix }}/credentials/idp-backchannel.p12
          -in    {{ shibidp_settings.prefix }}/credentials/idp-backchannel.crt
          -inkey {{ shibidp_settings.prefix }}/credentials/idp-backchannel.key
    - env:
        - SHIBIDP_KEYSTORE_PASSWORD:
            {{ shibidp_settings.keystore_password|yaml_encode }}
    - runas: {{ shibidp_settings.user }}
    - onchanges:
        - file: shibidp_keymat

{%- if grains['os_family'] == 'FreeBSD' %}

## The vendor hardcodes shell scripts to use /bin/bash, which doesn't
## exist in that location on all operating systems.  When necessary,
## this symlink gets created as a workaround.
shibidp_bash_symlink:
  file.symlink:
    - name: /bin/bash
    - target: /usr/local/bin/bash
    - require:
        - pkg: shibidp
    - require_in:
        - cmd: shibidp
        - cron: shibidp

{%- endif %}

## Handle inline metadata.
{%- for mp in shibidp_settings.metadata_providers
    if mp is string and not mp.startswith('http') %}
{%-   set mp_id = salt['hashutil.digest'](mp) %}
shibidp_inline_metadata_{{ loop.index0 }}:
  file.managed:
    - name: {{ shibidp_settings.prefix }}/metadata/{{ mp_id }}.xml
    - contents: {{ mp|yaml_encode }}
    - user: {{ shibidp_settings.user }}
    - group: {{ shibidp_settings.group }}
    - file_mode: 640            # FIXME: too strict?
    - require:
        - file: shibidp

{% else -%}
## NB: No inline metadata were specified.

{% endfor -%}

#### SHIBBOLETH/IDP/INIT.SLS ends here.
