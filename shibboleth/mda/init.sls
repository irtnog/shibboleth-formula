{% from "shibboleth/mda/map.jinja" import shibmda with context %}
{% set dirsep = '\\' if grains['os'] == 'Windows' else '/' %}
{% set destdir = '%s%saggregator-cli-%s'|format(shibmda.prefix, dirsep, shibmda.dist_version) %}

shibmda:
  pkg.installed:
    - pkgs: {{ shibmda.packages|yaml }}

  archive.extracted:
    - if_missing: {{ destdir }}
    - name: {{ shibmda.prefix }}
    - source: {{ shibmda.master_site }}/aggregator-cli-{{ shibmda.dist_version }}-bin.zip
    - source_hash: {{ shibmda.source_hash }}
    - archive_format: zip
    - keep: yes

  file.recurse:
    - name: {{ destdir|yaml_encode }}
    - source: salt://shibboleth/mda/files
    - template: jinja
    - context:
        dirsep: {{ dirsep|yaml_encode }}
        destdir: {{ destdir|yaml_encode }}
        schemas: {{ shibmda.schemas|yaml }}
        private_key: {{ shibmda.signing_key|yaml_encode }}
        all_entities_aggregate: {{ shibmda.all_entities_aggregate|yaml_encode }}
        idp_entities_aggregate: {{ shibmda.idp_entities_aggregate|yaml_encode }}
        sp_entities_aggregate: {{ shibmda.sp_entities_aggregate|yaml_encode }}
        validity_period: {{ shibmda.validity_period|yaml_encode }}
    - include_empty: yes
    - exclude_pat: E@\.gitignore
    - user: root
    - group: 0
    - dir_mode: 755
    - file_mode: 640
    - require:
        - archive: shibmda

  ## Refresh the aggregates now instead of waiting for the cron job.
  cmd.run:
    - name: java {{ shibmda.jvmopts }} -classpath {{ ['lib', '*']|join(dirsep)|yaml_squote }} net.shibboleth.metadata.cli.SimpleCommandLine {{ ['etc', 'config.xml']|join(dirsep)|yaml_squote }} main
    - cwd: {{ destdir|yaml_encode }}
    - env:
        UMASK: '022'
    - onchanges:
        - pkg: shibmda
        - archive: shibmda
        - file: shibmda
        - file: shibmda_source_metadata

{% if grains['os'] != 'Windows' %}
  cron.present:
    - identifier: shibmda
    - name: cd {{ destdir|yaml_squote }} && chronic java {{ shibmda.jvmopts }} -classpath {{ ['lib', '*']|join(dirsep)|yaml_squote }} net.shibboleth.metadata.cli.SimpleCommandLine {{ ['etc', 'config.xml']|join(dirsep)|yaml_squote }} main
    - minute: random
{% else %}
## TODO
{% endif %}

## The aggregator as configured reads every file in the `src/`
## directory.  This state manages the contents of this folder
## separately, letting Salt not only deploy source metadata to the
## aggregator but also remove stale metadata files from it.
shibmda_source_metadata:
  file.recurse:
    - name: {{ [destdir, 'src']|join(dirsep)|yaml_encode }}
    - source: salt://shibboleth/mda/sources
    - template: jinja
    - exclude_pat: E@\.gitignore
    - clean: True
    - user: root
    - group: 0
    - dir_mode: 755
    - file_mode: 640
    - require:
        - file: shibmda

## Don't bother cleaning up stale schema definitions because only the
## files referenced directly in config.xml get used for validation
## (unlike source metadata).
{% for schema in shibmda.schemas %}
shibmda_schema_{{ loop.index0 }}:
  file.managed:
    - name: {{ [destdir, 'schema', '%s.xsd'|format(loop.index0)]|join(dirsep)|yaml_encode }}
    - contents: {{ schema|yaml_encode }}
    - user: root
    - group: 0
    - mode: 644
    - require:
        - file: shibmda
    - onchanges_in:
        - cmd: shibmda
{% endfor %}
