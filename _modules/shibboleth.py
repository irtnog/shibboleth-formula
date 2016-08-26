#### SHIBBOLETH.PY --- shibboleth-formula helper functions

## Import Python libraries
import logging
try:
    from lxml import etree
    HAS_LXML = True
except ImportError:
    HAS_LXML = False
    try:
        # Python 2.5-2.7
        import xml.etree.cElementTree as etree
    except ImportError:
        try:
            # Python 2.5-2.7
            import xml.etree.ElementTree as etree
        except ImportError:
            try:
                # normal cElementTree install
                import cElementTree as etree
            except ImportError:
                # normal ElementTree install
                import elementtree.ElementTree as etree

## Import Salt libraries
import salt.exceptions
import salt.log

log = logging.getLogger(__name__)

## http://lxml.de/tutorial.html#namespaces
CONF_NAMESPACE = 'urn:mace:shibboleth:2.0:native:sp:config'
SAML_NAMESPACE = 'urn:oasis:names:tc:SAML:2.0:assertion'
SAMLP_NAMESPACE = 'urn:oasis:names:tc:SAML:2.0:protocol'
MD_NAMESPACE = 'urn:oasis:names:tc:SAML:2.0:metadata'
CONF = '{%s}' % CONF_NAMESPACE
SAML = '{%s}' % SAML_NAMESPACE
SAMLP = '{%s}' % SAMLP_NAMESPACE
MD = '{%s}' % MD_NAMESPACE
NSMAP = { None: CONF_NAMESPACE,
          'saml': SAML_NAMESPACE,
          'samlp': SAMLP_NAMESPACE,
          'md': MD_NAMESPACE }

def __virtual__():
    return 'shibboleth'

def _set_attribute(element, attribute, key, mapping):
    '''
    Adds an attribute to an element iff the key exists in the mapping.

    This tries to be clever about serializing the value of
    mapping[key].  For now it can handle booleans, which get
    translated to "true" or "false", and lists, which are simple
    catenations of values.  Everything else gets converted to strings
    using the str() function, which we hope does the right thing.
    '''
    if key in mapping:
        value = mapping[key]
        if type(value) == bool:
            ## convert True to "true", False to "false"
            value = str(value).lower()
        elif type(value) == list:
            ## convert [1, 2, 3] to "1 2 3"
            value = ' '.join(value)
        else:
            ## convert 1 to "1", "1" to "1", and hope for the best
            ## with other data types
            value = str(value)
        element.set(attribute, value)
    return

def _process_extensions(parent, extensions=[]):
    Extensions = etree.SubElement(parent, CONF + 'Extensions')
    for extension in extensions:
        nsmap = extension.nsmap if 'nsmap' in extension else {}
        ## FIXME: is the following necessary?
        # for prefix, uri in nsmap.items():
        #     etree.register_namespace(prefix,  uri)
        Library = etree.SubElement(Extensions, CONF + 'Library', nsmap)
        _set_attribute(Library, CONF + 'path', 'path', extension)
        _set_attribute(Library, CONF + 'fatal', 'fatal', extension)
        attributes = extension.attributes if 'attributes' in extension else {}
        for attribute in keys(attributes):
            ns_uri = ''
            attr = attribute
            if ':' in attribute:
                ## attribute is namespaced, so look up the namespace URI
                (prefix, attr) = attribute.split(':')
                try:
                    ns_uri = '{%s}' % nsmap[prefix]
                except:
                    ## attribute is namespaced, but the namespace
                    ## mapping wasn't specified, so silently drop
                    ## the prefix (technically, invalid XML)
                    ns_uri = ''
            _set_attribute(Library, ns_uri + attr, attribute, attributes)
        elements = extension.elements if 'elements' in extension else []
        for element in elements:
            Library.append(etree.fromstring(element))
    return

def generate_spconfig(settings={}):
    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPShibbolethXML
    SPConfig = etree.Element(CONF + 'SPConfig', nsmap=NSMAP) # lxml only!
    _set_attribute(SPConfig, CONF + 'logger',         'logger', settings)
    _set_attribute(SPConfig, CONF + 'clockSkew',      'clock_skew', settings)
    _set_attribute(SPConfig, CONF + 'unsafeChars',    'unsafe_chars', settings)
    _set_attribute(SPConfig, CONF + 'langFromClient', 'lang_from_client', settings)
    _set_attribute(SPConfig, CONF + 'langPriority',   'lang_priority', settings)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPShibbolethXMLExtensions
    if 'extensions' in settings:
        _process_extensions(SPConfig, settings.extensions)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPOutOfProcess
    if 'outofprocess_extensions' in settings:
        OutOfProcess = etree.SubElement(SPConfig, CONF + 'OutOfProcess')
        _set_attribute(OutOfProcess, CONF +  'logger',        'outofprocess_logger', settings)
        _set_attribute(OutOfProcess, CONF +  'catchAll',      'outofprocess_catchall', settings)
        _set_attribute(OutOfProcess, CONF +  'tranLogFormat', 'outofprocess_tranlog_format', settings)
        _set_attribute(OutOfProcess, CONF +  'tranLogFiller', 'outofprocess_tranlog_filler', settings)
        _process_extensions(OutOfProcess, settings.outofprocess_extensions)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPInProcess
    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPISAPI
    if any(k in settings for k in ['inprocess_extensions', 'inprocess_isapi_sites']):
        InProcess = etree.SubElement(SPConfig, CONF + 'InProcess')
        _set_attribute(InProcess, CONF + 'logger',           'inprocess_logger', settings)
        _set_attribute(InProcess, CONF + 'catchAll',         'inprocess_catchall', settings)
        _set_attribute(InProcess, CONF + 'unsetHeaderValue', 'inprocess_unset_header_value', settings)
        _set_attribute(InProcess, CONF + 'checkSpoofing',    'inprocess_check_spoofing', settings)
        _set_attribute(InProcess, CONF + 'spoofKey',         'inprocess_spoofkey', settings)
        _process_extensions(InProcess, settings.inprocess_extensions)
        if 'inprocess_isapi_sites' in settings:
            ISAPI = etree.SubElement(InProcess, CONF + 'ISAPI')
            _set_attribute(ISAPI, CONF + 'normalizeRequest', 'inprocess_isapi_normalize_request', settings)
            _set_attribute(ISAPI, CONF + 'safeHeaderNames',  'inprocess_isapi_safe_header_names', settings)
            for isapi_site in settings.inprocess_isapi_sites if 'inprocess_isapi_sites' in settings else []:
                Site = etree.SubElement(ISAPI, CONF + 'Site')
                _set_attribute(Site, CONF + 'id',     'id', isapi_site)
                _set_attribute(Site, CONF + 'name',   'name', isapi_site)
                _set_attribute(Site, CONF + 'scheme', 'scheme', isapi_site)
                _set_attribute(Site, CONF + 'port',    'port', isapi_site)
                _set_attribute(Site, CONF + 'sslport', 'sslport', isapi_site)
                for alias in isapi_site.aliases if 'aliases' in isapi_site else []:
                    Alias = etree.SubElement(Site, CONF + 'Alias')
                    Alias.text = etree.CDATA(alias)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPListener
    if any(k in settings
           for k in ['unixlistener_address',
                     'unixlistener_stacksize']):
        UnixListener = etree.SubElement(SPConfig, CONF + 'UnixListener')
        _set_attribute(UnixListener, CONF + 'address',   'unixlistener_address', settings)
        _set_attribute(UnixListener, CONF + 'stackSize', 'unixlistener_stacksize', settings)
    if any(k in settings
           for k in ['tcplistener_address',
                     'tcplistener_port',
                     'tcplistener_acl',
                     'tcplistener_stacksize']):
        TCPListener = etree.SubElement(SPConfig, CONF + 'TCPListener')
        _set_attribute(TCPListener, CONF + 'address',   'tcplistener_address', settings)
        _set_attribute(TCPListener, CONF + 'port',      'tcplistener_port', settings)
        _set_attribute(TCPListener, CONF + 'acl',       'tcplistener_acl', settings)
        _set_attribute(TCPListener, CONF + 'stackSize', 'tcplistener_stacksize', settings)
    # TODO: <Listener/>

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPStorageService
    if 'storage_services' in settings:
        for storage_service in settings.storage_services:
            StorageService = etree.SubElement(SPConfig, CONF + 'StorageService')
            _set_attribute(StorageService, CONF + 'type',            'type', storage_service)
            _set_attribute(StorageService, CONF + 'id',              'id', storage_service)
            _set_attribute(StorageService, CONF + 'cleanupInterval', 'cleanup_interval', storage_service)
            _set_attribute(StorageService, CONF + 'isolationLevel',  'isolation_level', storage_service)
            _set_attribute(StorageService, CONF + 'prefix',          'prefix', storage_service)
            _set_attribute(StorageService, CONF + 'buildMap',        'build_map', storage_service)
            _set_attribute(StorageService, CONF + 'sendTimeout',     'send_timeout', storage_service)
            _set_attribute(StorageService, CONF + 'recvTimeout',     'recv_timeout', storage_service)
            _set_attribute(StorageService, CONF + 'pollTimeout',     'poll_timeout', storage_service)
            _set_attribute(StorageService, CONF + 'failLimit',       'fail_limit', storage_service)
            _set_attribute(StorageService, CONF + 'retryTimeout',    'retry_timeout', storage_service)
            _set_attribute(StorageService, CONF + 'nonBlocking',     'nonblocking', storage_service)
            if 'connection_string' in storage_service:
                ConnectionString = etree.SubElement(StorageService, CONF + 'ConnectionString')
                ConnectionString.text = etree.CDATA(str(storage_service.connection_string))
            if 'retry_on_error' in storage_service:
                RetryOnError = etree.SubElement(StorageService, CONF + 'RetryOnError')
                RetryOnError.text = etree.CDATA(str(storage_service.retry_on_error))
            if 'hosts' in storage_service:
                Hosts = etree.SubElement(StorageService, CONF + 'Hosts')
                Hosts.txt = ', '.join(storage_service.hosts)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPSessionCache
    if 'session_cache_type' in settings:
        SessionCache = etree.SubElement(SPConfig, CONF + 'SessionCache')
        _set_attribute(SessionCache, CONF + 'type',                 'session_cache_type', settings)
        _set_attribute(SessionCache, CONF + 'cacheAllowance',       'session_cache_allowance', settings)
        _set_attribute(SessionCache, CONF + 'cacheTimeout',         'session_cache_timeout', settings)
        _set_attribute(SessionCache, CONF + 'maintainReverseIndex', 'session_cache_maintain_reverse_index', settings)
        _set_attribute(SessionCache, CONF + 'excludeReverseIndex',  'session_cache_exclude_reverse_index', settings)
        _set_attribute(SessionCache, CONF + 'StorageService',       'session_cache_storage_service', settings)
        _set_attribute(SessionCache, CONF + 'StorageServiceLite',   'session_cache_storage_service_lite', settings)
        _set_attribute(SessionCache, CONF + 'cleanupInterval',      'session_cache_cleanup_interval', settings)
        _set_attribute(SessionCache, CONF + 'inprocTimeout',        'session_cache_inprocess_timeout', settings)
        _set_attribute(SessionCache, CONF + 'cacheAssertions',      'session_cache_cache_assertions', settings)
        _set_attribute(SessionCache, CONF + 'inboundHeader',        'session_cache_inbound_header', setting)
        _set_attribute(SessionCache, CONF + 'outboundHeader',       'session_cache_outbound_header', settings)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPReplayCache
    if 'replay_cache_storage_service' in settings:
        ReplayCache = etree.SubElement(SPConfig, CONF + 'ReplayCache')
        _set_attribute(ReplayCache, CONF + 'StorageService', 'replay_cache_storage_service', settings)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPArtifactMap
    if any(k in settings
           for k in ['artifact_map_ttl',
                     'artifact_map_storage_service',
                     'artifact_map_context']):
        ArtifactMap = etree.SubElement(SPConfig, CONF + 'ArtifactMap')
        _set_attribute(ArtifactMap, 'artifactTTL',    'artifact_map_ttl', settings)
        _set_attribute(ArtifactMap, 'StorageService', 'artifact_map_storage_service', settings)
        _set_attribute(ArtifactMap, 'context',        'artifact_map_context', settings)

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPRequestMapper
    if any(k in settings
           for k in ['request_map',
                     'request_mapper_type',
                     'request_mapper_auth_type',
                     'request_mapper_app_id',
                     'request_mapper_require_session',
                     'request_mapper_require_session_with',
                     'request_mapper_export_assertion',
                     'request_mapper_redirect_to_ssl',
                     'request_mapper_entity_id',
                     'request_mapper_is_passive',
                     'request_mapper_force_authn',
                     'request_mapper_authn_context_class_ref',
                     'request_mapper_authn_context_comparison',
                     'request_mapper_redirect_errors',
                     'request_mapper_session_error',
                     'request_mapper_metadata_error',
                     'request_mapper_access_error',
                     'request_mapper_ssl_error',
                     'request_mapper_remote_addr',
                     'request_mapper_target',
                     'request_mapper_encoding',
                     'request_mapper_nameid_format',
                     'request_mapper_spname_qualifier',
                     'request_mapper_export_stdvars',
                     'request_mapper_export_cookie',
                     'request_mapper_discovery_url',
                     'request_mapper_discovery_policy',
                     'request_mapper_require_logout_with',
                     'request_mapper_export_duplicate_values']):
        RequestMapper = etree.SubElement(SPConfig, CONF + 'RequestMapper')
        _set_attribute(RequestMapper, CONF + 'type',                   'request_mapper_type', settings)
        _set_attribute(RequestMapper, CONF + 'authType',               'request_mapper_auth_type', settings)
        _set_attribute(RequestMapper, CONF + 'applicationId',          'request_mapper_app_id', settings)
        _set_attribute(RequestMapper, CONF + 'requireSession',         'request_mapper_require_session', settings)
        _set_attribute(RequestMapper, CONF + 'requireSessionWith',     'request_mapper_require_session_with', settings)
        _set_attribute(RequestMapper, CONF + 'exportAssertion',        'request_mapper_export_assertion', settings)
        _set_attribute(RequestMapper, CONF + 'redirectToSSL',          'request_mapper_redirect_to_ssl', settings)
        _set_attribute(RequestMapper, CONF + 'entityID',               'request_mapper_entity_id', settings)
        _set_attribute(RequestMapper, CONF + 'isPassive',              'request_mapper_is_passive', settings)
        _set_attribute(RequestMapper, CONF + 'forceAuthn',             'request_mapper_force_authn', settings)
        _set_attribute(RequestMapper, CONF + 'authnContextClassRef',   'request_mapper_authn_context_class_ref', settings)
        _set_attribute(RequestMapper, CONF + 'authnContextComparison', 'request_mapper_authn_context_comparison', settings)
        _set_attribute(RequestMapper, CONF + 'redirectErrors',         'request_mapper_redirect_errors', settings)
        _set_attribute(RequestMapper, CONF + 'sessionError',           'request_mapper_session_error', settings)
        _set_attribute(RequestMapper, CONF + 'metadataError',          'request_mapper_metadata_error', settings)
        _set_attribute(RequestMapper, CONF + 'accessError',            'request_mapper_access_error', settings)
        _set_attribute(RequestMapper, CONF + 'sslError',               'request_mapper_ssl_error', settings)
        _set_attribute(RequestMapper, CONF + 'REMOTE_ADDR',            'request_mapper_remote_addr', settings)
        _set_attribute(RequestMapper, CONF + 'target',                 'request_mapper_target', settings)
        _set_attribute(RequestMapper, CONF + 'encoding',               'request_mapper_encoding', settings)
        _set_attribute(RequestMapper, CONF + 'NameIDFormat',           'request_mapper_nameid_format', settings)
        _set_attribute(RequestMapper, CONF + 'SPNameQualifier',        'request_mapper_spname_qualifier', settings)
        _set_attribute(RequestMapper, CONF + 'exportStdVars',          'request_mapper_export_stdvars', settings)
        _set_attribute(RequestMapper, CONF + 'exportCookie',           'request_mapper_export_cookie', settings)
        _set_attribute(RequestMapper, CONF + 'discoveryURL',           'request_mapper_discovery_url', settings)
        _set_attribute(RequestMapper, CONF + 'discoveryPolicy',        'request_mapper_discovery_policy', settings)
        _set_attribute(RequestMapper, CONF + 'requireLogoutWith',      'request_mapper_require_logout_with', settings)
        _set_attribute(RequestMapper, CONF + 'exportDuplicateValues',  'request_mapper_export_duplicate_values', settings)
        if 'request_map' in settings:
            

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPApplication

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPSecurityPolicies

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPShibbolethXML#

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPTransportOption

    ## https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPReloadableXMLFile

    return etree.tostring(SPConfig,
                          xml_declaration=True,
                          encoding='utf-8',
                          pretty_print=True)

### Local Variables:
### coding: utf-8
### End:

#### SHIBBOLETH.PY ends here.
