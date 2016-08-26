{%- from "shibboleth/idp/map.jinja" import shibidp_settings with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ shibidp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ shibidp_settings.version }}/bin/install.sh \
    -Didp.src.dir={{ shibidp_settings.prefix }}/vendor/shibboleth-identity-provider-{{ shibidp_settings.version }} \
    -Didp.target.dir={{ shibidp_settings.prefix }} \
    -Didp.sealer.password={{ shibidp_settings.sealer_password|yaml_squote }} \
    -Didp.host.name={{ shibidp_settings.hostname }} \
    -Didp.scope={{ shibidp_settings.scope }} \
    -Didp.merge.properties={{ shibidp_settings.prefix }}/conf/idp.merge.properties \
    -Didp.keystore.password={{ shibidp_settings.keystore_password|yaml_squote }} \
    -Didp.noprompt=1 \
    -Didp.no.tidy=1
