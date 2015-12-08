{% from "shibboleth/sp/map.jinja" import sp_settings with context %}

shibboleth_sp:
  pkg.installed:
    - pkgs: {{ sp_settings.packages|yaml }}
