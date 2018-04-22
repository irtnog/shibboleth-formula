{%- from "shibboleth/idp/map.jinja" import shibidp with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

SEALER_PASSWORD=$(cat {{ shibidp.prefix }}/credentials/sealer.pass)
export SEALER_PASSWORD

{{ shibidp.prefix }}/bin/seckeygen.sh \
    --storefile {{ shibidp.prefix }}/credentials/sealer.jks \
    --storepass "${SEALER_PASSWORD}" \
    --versionfile {{ shibidp.prefix }}/credentials/sealer.kver \
    --alias secret
