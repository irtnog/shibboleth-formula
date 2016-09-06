# shibboleth-formula

This Salt state formula installs and configures
[Shibboleth](http://shibboleth.net/), a free and open-source federated
identity solution that provides Single Sign-On capabilities and allows
sites to make informed authorization decisions for individual access
of protected online resources in a privacy-preserving manner.

## Available States

* **shibboleth.idp**

  Installs and configures the Shibboleth Identity Provider (IdP).
  Currently, only very simple attribute generation and attribute
  release rules are supported.

* **shibboleth.sp**

  Installs and configures the Shibboleth Service Provider (SP).

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

  At a minimum this is a list of URLs, from which the IdP can download
  the XML metadata of trusted service providers.

### Shibboleth SP

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

* **shibboleth:sp:sso_default_idp** or
  **shibboleth:sp:sso_discovery_url**

  Either unconditionally redirect users to a single identity provider,
  or send users to a discovery service, where they can choose one of
  the trusted identity providers.  For more information please refer
  to
  [Native SP Service SSO](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPServiceSSO).

* **shibboleth:sp:metadata_providers**

  At a minimum this is a list of URLs, from which the SP can download
  the XML metadata of trusted identity providers.
