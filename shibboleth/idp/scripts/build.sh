{%- from "shibboleth/idp/map.jinja" import shibidp with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ shibidp.prefix }}/bin/build.sh -Didp.home={{ shibidp.prefix|yaml_squote }} -Didp.noprompt=1
