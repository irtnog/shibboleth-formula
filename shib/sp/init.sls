{% from "shib/sp/map.jinja" import shibsp_settings with context %}

shibsp:
  pkg.installed:
    - pkgs: {{ shibsp_settings.packages|yaml }}
