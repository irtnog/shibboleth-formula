{% from "shibboleth/ds/map.jinja" import shibds_settings %}
{% set dirsep = '\\' if grains['os_family'] == 'Windows' else '/' %}

{% if shibds_settings.packages == [] %}
shibds_dist:
  archive.extracted:
    - name: {{ shibds_settings.prefix|yaml_encode }}
    - source: {{ 'http://shibboleth.net/downloads/embedded-discovery-service/latest/shibboleth-embedded-ds-%s.zip'|format(shibds_settings.dist_version)|yaml_encode }}
    - source_hash: {{ 'http://shibboleth.net/downloads/embedded-discovery-service/latest/shibboleth-embedded-ds-%s.zip.sha256'|format(shibds_settings.dist_version)|yaml_encode }}
    ## TODO: source_hash_update
    - archive_format: zip
    - user: {{ shibds_settings.user|yaml_encode }}
    - group: {{ shibds_settings.group|yaml_encode }}
    - if_missing: {{ shibds_settings.conffile|yaml_encode }}
    - require_in:
        - file: shibds
{% endif %}

shibds:
  pkg.installed:
    - pkgs: {{ shibds_settings.packages|yaml }}

  file.managed:
    - name: {{ shibds_settings.conffile|yaml_encode }}
    - source: salt://shibboleth/ds/files/idpselect_config.js
    - template: jinja
    - user: {{ shibds_settings.user|yaml_encode }}
    - group: {{ shibds_settings.group|yaml_encode }}
    - mode: 644
    - require:
        - pkg: shibds
