{%- from "shib/idp/map.jinja" import shibidp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

SEALER_PASSWORD=$(cat {{ shibidp_settings.prefix }}/credentials/sealer.pass)
export SEALER_PASSWORD

{{ shibidp_settings.prefix }}/bin/seckeygen.sh \
    --storefile {{ shibidp_settings.prefix }}/credentials/sealer.jks \
    --storepass "${SEALER_PASSWORD}" \
    --versionfile {{ shibidp_settings.prefix }}/credentials/sealer.kver \
    --alias secret
