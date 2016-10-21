{% from "xmlsectool/map.jinja" import xmlsectool_settings with context %}

xmlsectool:
  pkg.installed:
    - pkgs: {{ xmlsectool_settings.packages|yaml }}

  archive.extracted:
    - if_missing: {{ xmlsectool_settings.prefix }}/xmlsectool-{{ xmlsectool_settings.dist_version }}
    - name: {{ xmlsectool_settings.prefix }}
    - source: {{ xmlsectool_settings.master_site }}/xmlsectool-{{ xmlsectool_settings.dist_version }}-bin.zip
    - source_hash: {{ xmlsectool_settings.source_hash }}
    - archive_format: zip
    - keep: yes

