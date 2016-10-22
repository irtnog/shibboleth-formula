{% from "xmlsectool/map.jinja" import xmlsectool_settings with context %}
{% set destdir = '%s/xmlsectool-%s'|format(xmlsectool_settings.prefix, xmlsectool_settings.dist_version) %}

xmlsectool:
  pkg.installed:
    - pkgs: {{ xmlsectool_settings.packages|yaml }}

  archive.extracted:
    - if_missing: {{ destdir }}
    - name: {{ xmlsectool_settings.prefix }}
    - source: {{ xmlsectool_settings.master_site }}/xmlsectool-{{ xmlsectool_settings.dist_version }}-bin.zip
    - source_hash: {{ xmlsectool_settings.source_hash }}
    - archive_format: zip
    - keep: yes

  file.recurse:
    - name: {{ destdir }}
    - source: salt://xmlsectool/files
    - template: jinja
    - include_empty: yes
    - exclude_pat: .gitignore
    - user: root
    - group: 0
    - dir_mode: 755
    - file_mode: 640
    - require:
        - archive: xmlsectool

{% for entity, metadata in xmlsectool_settings.entities|dictsort %}
xmlsectool_entity_{{ loop.index0 }}:
  file.managed:
    - name: {{ destdir }}/metadata/unsigned/{{ entity }}.xml
    - contents: {{ metadata|yaml_encode }}
    - user: root
    - group: 0
    - mode: 644
    - require:
        - file: xmlsectool
  cmd.run:
    - name: java -Xmx256m -classpath 'lib/*' net.shibboleth.tool.xmlsectool.XMLSecTool --sign --inFile metadata/unsigned/{{ entity }}.xml --outFile metadata/signed/{{ entity }}.xml --certificate conf/signing.cert --key conf/signing.key
    - cwd: {{ destdir }}
    - env:
        UMASK: '022'
    - onchanges:
        - pkg: xmlsectool
        - archive: xmlsectool
        - file: xmlsectool
        - file: xmlsectool_entity_{{ loop.index0 }}
{% endfor %}
