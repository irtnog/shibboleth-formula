# shibboleth-formula

This Salt state formula installs and configures
[Shibboleth](http://shibboleth.net/), a free and open-source federated
identity solution that provides Single Sign-On capabilities and allows
sites to make informed authorization decisions for individual access
of protected online resources in a privacy-preserving manner.

## Available States

* **shibboleth.repo**

  Enables either the OpenSUSE Build Service (on RHEL/SUSE) or the
  SWITCH AAI (on Debian/Ubuntu) binary package repositories.

* **shibboleth.idp**

  Installs and configures the Shibboleth Identity Provider (IdP).
  Currently, only very simple attribute generation and attribute
  release rules are supported.

* **shibboleth.mda**

  Installs, configures, and runs the CLI version of the Shibboleth
  Metadata Aggregator (MA a/k/a MDA).  On supported versions of
  Unix/Linux, this also creates a cron(8) job to refresh the generated
  metadata aggregates on an hourly basis.

* **shibboleth.sp**

  Installs and configures the Shibboleth Service Provider (SP).

* **shibboleth.ds**

  Installs and configures the Shibboleth Embedded Discovery Service
  (EDS).

* **xmlsectool**

  Installs and configures xmlsectool, and signs SAML metadata
  specified in Pillar data.

## Configuration

Additional settings and more complicated configurations are possible;
for examples refer to [pillar.example](pillar.example).

### Shibboleth IdP

At a minimum one must set the following Pillar keys in order to
successfully deploy the identity provider:

* **shibboleth:idp:hostname**

  The IdP's fully qualified domain name, e.g., `login.example.com`.

* **shibboleth:idp:entity_id**

  The IdP's SAML entity ID, e.g.,
  `https://login.example.com/idp/shibboleth`.

* **shibboleth:idp:scope**

  The IdP's scope, used in the eduPersonScopedAffiliation,
  eduPeronPrincipalName, and eduPersonUniqueId assertions, e.g.,
  `example.com`.  For more information please refer to
  [Scope in Metadata](https://spaces.internet2.edu/display/InCFederation/Scope+in+Metadata)
  and
  [Scoped User Identifiers](https://spaces.internet2.edu/display/InCFederation/2016/05/08/Scoped+User+Identifiers).

* **shibboleth:idp:keystore_password**

  This password, restricted to alphanumeric characters, will be used
  to encrypt any JCEKS or PKCS#12 keystores used by the IdP to store
  keying material.  For more information please refer to
  [Security Configuration](https://wiki.shibboleth.net/confluence/display/IDP30/SecurityConfiguration)
  and
  [Secret Key Management](https://wiki.shibboleth.net/confluence/display/IDP30/SecretKeyManagement).

* **shibboleth:idp:sealer_password**

  This password, restricted to alphanumeric characters and usually set
  to the same value as the keystore password, will be used to encrypt
  the data sealer key, which the IdP uses to secure cookies and other
  internal data.  For more information please refer to
  [Security Configuration](https://wiki.shibboleth.net/confluence/display/IDP30/SecurityConfiguration)
  and
  [Secret Key Management](https://wiki.shibboleth.net/confluence/display/IDP30/SecretKeyManagement).

* **shibboleth:idp:backchannel_certificate** and
  **shibboleth:idp:backchannel_key**

  This key-pair (a DER-encoded X.509 certificate and private key in
  base64 format) enables TLS on the SOAP back-channel used for
  attribute query, SAML artifacts, and back-channel logout.  For more
  information please refer to
  [Security and Networking](https://wiki.shibboleth.net/confluence/display/IDP30/SecurityAndNetworking).

* **shibboleth:idp:encryption_certificate** and
  **shibboleth:idp:encryption_key**

  This key-pair (a DER-encoded X.509 certificate and private key in
  base64 format) supports inbound XML encryption.

* **shibboleth:idp:signing_certificate** and
  **shibboleth:idp:signing_key**

  The IdP uses this key-pair (a DER-encoded X.509 certificate and
  private key in base64 format) to sign SAML messages.  For more
  information please refer to
  [Security and Networking](https://wiki.shibboleth.net/confluence/display/IDP30/SecurityAndNetworking).

* **shibboleth.idp:metadata_providers**

  At a minimum this is a list of URLs from which the IdP can download
  the XML metadata of trusted service providers.

### Shibboleth SP

At a minimum one must set the following Pillar keys in order to
successfully deploy the service provider:

* **shibboleth:sp:entity_id**

  The SP's SAML entity ID, e.g., `https://www.example.com/shibboleth`.

* **shibboleth:sp:encryption_certificate** and
  **shibboleth:sp:encryption_key**

  This key-pair (a DER-encoded X.509 certificate and private key in
  base64 format) supports inbound XML encryption.

* **shibboleth:sp:signing_certificate** and
  **shibboleth:sp:signing_key**

  The SP uses this key-pair (a DER-encoded X.509 certificate and
  private key in base64 format) to sign SAML messages.

* **shibboleth:sp:sso_default_idp**, or
  **shibboleth:sp:sso_discovery_protocol** and
  **shibboleth:sp:sso_discovery_url**

  Either unconditionally redirect users to a single identity provider,
  or send users to a discovery service, where they can choose one of
  the trusted identity providers.  For more information please refer
  to
  [Native SP Service SSO](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPServiceSSO).

* **shibboleth:sp:metadata_providers**

  At a minimum this is a list of URLs, from which the SP can download
  the XML metadata of trusted identity providers.

### Shibboleth EDS

Configuration of the embedded discovery service is optional.

### Shibboleth MDA

At a minimum one must set the following Pillar keys in order to
successfully deploy the CLI version of the metadata aggregator:

* **shibboleth:mda:signing_key*

  This key (a DER-encoded X.509 private key in base64 format) is
  required for XML document signing.

* **shibboleth:mda:all_entities_aggregate**,
  **shibboleth:mda:idp_entities_aggregate**, and
  **shibboleth:mda:sp_entities_aggregate**

  These are pathnames denoting the location of the respective
  aggregates on the minion's file system.

### xmlsectool

One must set the following Pillar keys in order to use this state:

* **xmlsectool:signing_certificate** and
  **xmlsectool:signing_key**

  This key-pair (a DER-encoded X.509 certificate and private key in
  base64 format) is required for XML document signing.

* **xmlsectool:entities**

  A dictionary containing XML metadata, keyed using identifiers
  following the same format
  as [XML identifiers](http://www.datypic.com/sc/xsd/t-xsd_ID.html).

## Deployment

The IdP must be hosted by a suitable Java servlet container, such as
Tomcat's Catalina or Jetty.  For an example Tomcat configuration,
please refer to
[pillar.example from tomcat-formula](https://github.com/irtnog/tomcat-formula/blob/master/pillar.example)
as well as the "glue" state
[tomcat.shibboleth-idp](https://github.com/irtnog/tomcat-formula/blob/master/tomcat/shibboleth-idp.sls).

Likewise, the SP interfaces with the web server.  For example, the
following configures Apache httpd 2.4 to authenticate users via
Shibboleth, using the discovery service to choose their IdP:

```
LoadModule mod_shib /usr/local/lib/shibboleth/mod_shib_24.so

<Location /Shibboleth.sso>
  SetHandler shib
</Location>

Alias /shibboleth-ds /etc/shibboleth-ds
<Location /shibboleth-ds>
  AuthType shibboleth
  ShibRequestSetting requireSession false
  Require shibboleth
</Location>

<LocationMatch "^/login">
  AuthType shibboleth
  ShibRequestSetting requireSession 1
  Require valid-user
</LocationMatch>
```
