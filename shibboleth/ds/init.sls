{% from "shibboleth/ds/map.jinja" import shibds %}
{% set dirsep = '\\' if grains['os_family'] == 'Windows' else '/' %}

{% if shibds.packages == [] %}
shibds_dist:
  archive.extracted:
    - name: {{ shibds.prefix|yaml_encode }}
    - source: {{ 'http://shibboleth.net/downloads/embedded-discovery-service/latest/shibboleth-embedded-ds-%s.zip'|format(shibds.dist_version)|yaml_encode }}
    - source_hash: {{ 'http://shibboleth.net/downloads/embedded-discovery-service/latest/shibboleth-embedded-ds-%s.zip.sha256'|format(shibds.dist_version)|yaml_encode }}
    ## TODO: source_hash_update
    - archive_format: zip
    - user: {{ shibds.user|yaml_encode }}
    - group: {{ shibds.group|yaml_encode }}
    - if_missing: {{ shibds.conffile|yaml_encode }}
    - require_in:
        - file: shibds
{% endif %}

shibds:
  pkg.installed:
    - pkgs: {{ shibds.packages|yaml }}

  file.managed:
    - name: {{ shibds.conffile|yaml_encode }}
    - source: salt://shibboleth/ds/files/idpselect_config.js
    - template: jinja
    - user: {{ shibds.user|yaml_encode }}
    - group: {{ shibds.group|yaml_encode }}
    - mode: 644
    - require:
        - pkg: shibds
