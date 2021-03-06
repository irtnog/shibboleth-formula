{%- from "tomcat/map.jinja" import tomcat with context %}
{%- from "shibboleth/idp/map.jinja" import shibidp with context %}

include:
  - shibboleth.idp
  - tomcat
  - tomcat.config

extend:
  tomcat:
    pkg:
      - require_in:
          ## These Shibboleth IdP states may reference the service
          ## account created by the Tomcat package installation
          ## state.
          - file: shibidp
          - archive: shibidp
          - cmd: shibidp
          - cron: shibidp
          - file: shibidp_keymat
          - cmd: shibidp_keymat
          {%- for mp in shibidp.metadata_providers
              if mp is string and not mp.startswith('http') %}
          - file: shibidp_inline_metadata_{{ loop.index0 }}
          {%- endfor %}
    service:
      - watch:
          ## Changes to the Shibboleth IdP installation should trigger
          ## a restart (FIXME: reload just that context?) of the
          ## Tomcat service.  This takes the belt-and-suspenders
          ## approach to defining watch requsites.
          - file: shibidp
          - cmd: shibidp
          - file: shibidp_keymat
          - cmd: shibidp_keymat
          - file: shibidp_tomcat_jstl
          - cmd: shibidp_tomcat_jstl
          {%- for mp in shibidp.metadata_providers
              if mp is string and not mp.startswith('http') %}
          - file: shibidp_inline_metadata_{{ loop.index0 }}
          {%- endfor %}

shibidp_tomcat:
  file.managed:
    - name: {{ tomcat.conf_dir }}/Catalina/localhost/idp.xml
    - source: salt://tomcat/files/idp.xml
    - template: jinja
    - require:
        - pkg: tomcat
    - watch_in:
        - service: tomcat

{%- if 'selinux' in salt['sys.list_modules']()
    and salt['selinux.getenforce']() == 'Enforcing' %}

shibidp_tomcat_fcontext:
  selinux.fcontext_policy_present:
    - names:
        - {{ shibidp.prefix }}/metadata(/.*)?
        - {{ shibidp.prefix }}/logs(/.*)?
    - sel_type: tomcat_cache_t
    - require:
        - pkg: tomcat

shibidp_tomcat_restorecon:
  selinux.fcontext_policy_applied:
    - names:
        - {{ shibidp.prefix }}/metadata
        - {{ shibidp.prefix }}/logs
    - recursive: True
    - require:
        - file: shibidp
        - archive: shibidp
        - file: shibidp_keymat
{%-   for mp in shibidp.metadata_providers
      if mp is string and not mp.startswith('http') %}
        - file: shibidp_inline_metadata_{{ loop.index0 }}
{%-   endfor %}
        - selinux: shibidp_tomcat_fcontext
    - watch_in:
        - service: tomcat

{%- endif %}

## Tomcat does not provide the Java Server Tag Library, which is
## required to use JSP pages as Spring views.  The IdP status page at
## /idp/status is built with JSP and will not work without this
## library.
shibidp_tomcat_jstl:
  file.managed:
    - name: {{ shibidp.prefix }}/edit-webapp/WEB-INF/lib/jstl-{{ shibidp.jstl_version }}.jar
    - source: {{ shibidp.jstl_source_template|format(shibidp.jstl_version, shibidp.jstl_version) }}
    - source_hash: {{ shibidp.jstl_source_hash }}
    - user: {{ shibidp.user }}
    - group: {{ shibidp.group }}
    - mode: 644
    - require:
        - cmd: shibidp
  cmd.wait_script:
    - source: salt://shibboleth/idp/scripts/build.sh
    - template: jinja
    - user: {{ shibidp.user }}
    - group: {{ shibidp.group }}
    - watch:
        - file: shibidp_tomcat_jstl
