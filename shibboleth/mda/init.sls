{% from "shibboleth/mda/map.jinja" import shibmda_settings with context %}

shibmda:
  pkg.installed:
    - pkgs: {{ shibmda_settings.packages|yaml }}

  archive.extracted:
    - if_missing: {{ shibmda_settings.prefix }}/aggregator-cli-{{ shibmda_settings.dist_version }}
    - name: {{ shibmda_settings.prefix }}
    - source: {{ shibmda_settings.master_site }}/aggregator-cli-{{ shibmda_settings.dist_version }}-bin.zip
    - source_hash: {{ shibmda_settings.source_hash }}
    - archive_format: zip
    - keep: yes
