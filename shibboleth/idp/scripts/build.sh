{%- from "shibboleth/idp/map.jinja" import shibidp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ shibidp_settings.prefix }}/bin/build.sh -Didp.home={{ shibidp_settings.prefix|yaml_squote }} -Didp.noprompt=1
