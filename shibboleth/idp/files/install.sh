{%- from "shibboleth/idp/map.jinja" import idp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ idp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ idp_settings.version }}/bin/install.sh \
    -Didp.src.dir={{ idp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ idp_settings.version }} \
    -Didp.target.dir={{ idp_settings.prefix }} \
    -Didp.sealer.password={{ idp_settings.sealer_password }} \
    -Didp.host.name={{ idp_settings.hostname }} \
    -Didp.scope={{ idp_settings.scope }} \
    -Didp.merge.properties={{ idp_settings.prefix }}/conf/idp.merge.properties \
    -Didp.keystore.password={{ idp_settings.keystore_password }} \
    -Didp.noprompt=1 \
    -Didp.no.tidy=1
