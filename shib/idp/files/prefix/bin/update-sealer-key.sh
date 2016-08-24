{%- from "shib/idp/map.jinja" import shibidp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ shibidp_settings.prefix }}/bin/seckeygen.sh \
    --storefile {{ shibidp_settings.prefix }}/credentials/sealer.jks \
    --storepass {{ shibidp_settings.sealer_password|yaml_squote }} \
    --versionfile {{ shibidp_settings.prefix }}/credentials/sealer.kver \
    --alias secret
