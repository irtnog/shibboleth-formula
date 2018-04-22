{%- from "shibboleth/idp/map.jinja" import shibidp with context -%}
#!/bin/sh

JAVA_HOME=$(java -XshowSettings:java.home -version 2>&1 \
		| fgrep java.home \
		| awk '{print $3}')
export JAVA_HOME

{{ shibidp.prefix }}/vendor/shibboleth-identity-provider-{{ shibidp.version }}/bin/install.sh \
    -Didp.src.dir={{ shibidp.prefix }}/vendor/shibboleth-identity-provider-{{ shibidp.version }} \
    -Didp.target.dir={{ shibidp.prefix }} \
    -Didp.sealer.password={{ shibidp.sealer_password|yaml_squote }} \
    -Didp.host.name={{ shibidp.hostname }} \
    -Didp.scope={{ shibidp.scope }} \
    -Didp.merge.properties={{ shibidp.prefix }}/conf/idp.merge.properties \
    -Didp.keystore.password={{ shibidp.keystore_password|yaml_squote }} \
    -Didp.noprompt=1 \
    -Didp.no.tidy=1
