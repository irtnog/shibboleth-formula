{%- from "shibboleth/idp/map.jinja" import idp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ idp_settings.prefix }}/bin/seckeygen.sh \
    --storefile {{ idp_settings.prefix }}/credentials/sealer.jks \
    --storepass {{ idp_settings.sealer_password }} \
    --versionfile {{ idp_settings.prefix }}/credentials/sealer.kver \
    --alias secret
