/* IDPSELECT_CONFIG.JS --- Shibboleth EDS configuration

   THIS FILE IS MANAGED BY SALT.  Any changes to it will be
   overwritten during the next state run. */
{%- from "shibboleth/ds/map.jinja" import shibds_settings %}

/** @class IdP Selector UI */
function IdPSelectUIParms(){
    this.alwaysShow = {{ 'true' if shibds_settings.always_show else 'false' }};
    this.dataSource = '{{ shibds_settings.data_source }}';
    this.defaultLanguage = '{{ shibds_settings.default_language }}';
    this.defaultLogo = '{{ shibds_settings.default_logo }}';
    this.defaultLogoWidth = {{ shibds_settings.default_logo_width }};
    this.defaultLogoHeight = {{ shibds_settings.default_logo_height }};
    this.defaultReturn = {{ 'null' if shibds_settings.default_return == None else "'%s'"|format(shibds_settings.default_return) }};
    this.defaultReturnIDParam = {{ 'null' if shibds_settings.default_return_id_param == None else "'%s'"|format(shibds_settings.default_return) }};
    this.helpURL = '{{ shibds_settings.help_url }}';
{%- for hack in shibds_settings.ie6_hack %}
{%- if loop.first %}
    this.ie6Hack = [
{%- endif %}
{%- if loop.last %}
        {{ hack }}
      ];
{%- else %}
        {{ hack }},
{%- endif %}
{%- else %}
    this.ie6Hack = null;
{%- endfor %}
    this.insertAtDiv = '{{ shibds_settings.insert_at_div }}';
    this.maxResults = {{ shibds_settings.max_results }};
    this.myEntityID = {{ 'null' if shibds_settings.my_entity_id == None else "'%s'"|format(shibds_settings.my_entity_id) }};
{%- for entity_id in shibds_settings.preferred_idps %}
{%- if loop.first %}
    this.preferredIdP = [
{%- endif %}
{%- if loop.last %}
        '{{ entity_id }}'
      ]
{%- else %}
        '{{ entity_id }}',
{%- endif %}
{%- else %}
    this.preferredIdP = null;
{%- endfor %}
{%- for entity_id in shibds_settings.hidden_idps %}
{%- if loop.first %}
    this.hiddenIdPs = [
{%- endif %}
{%- if loop.last %}
        '{{ entity_id }}'
      ]
{%- else %}
        '{{ entity_id }}',
{%- endif %}
{%- else %}
    this.hiddenIdPs = null;
{%- endfor %}
    this.ignoreKeywords = {{ 'true' if shibds_settings.ignore_keywords else 'false' }};
    this.showListFirst = {{ 'true' if shibds_settings.show_list_first else 'false' }};
    this.samlIdPCookieTTL = {{ shibds_settings.saml_idp_cookie_ttl }};
    this.setFocusTextBox = {{ 'true' if shibds_settings.set_focus_text_box else 'false' }};
    this.testGUI = {{ 'true' if shibds_settings.test_gui else 'false' }};

{%- set language_bundle_setting_map = {
    'fatal_div_missing': 'fatal.divMissing',
    'fatal_no_xmlhttprequest': 'fatal.noXMLHttpRequest',
    'fatal_wrong_protocol': 'fatal.wrongProtocol',
    'fatal_wrong_entityid': 'fatal.wrongEntityId',
    'fatal_no_data': 'fatal.noData',
    'fatal_load_failed': 'fatal.loadFailed',
    'fatal_no_parameters': 'fatal.noparms',
    'fatal_no_return_url': 'fatal.noReturnURL',
    'fatal_bad_protocol': 'fatal.badProtocol',
    'idp_preferred_label': 'idpPreferred.label',
    'idp_entry_label': 'idpEntry.label',
    'idp_entry_nopreferred_label': 'idpEntry.NoPreferred.label',
    'idp_list_label': 'idpList.label',
    'idp_list_nopreferred_label': 'idpList.NoPreferred.label',
    'idp_list_default_option_label': 'idpList.defaultOptionLabel',
    'idp_list_show_list': 'idpList.showList',
    'idp_list_show_search': 'idpList.showSearch',
    'submit_button_label': 'submitButton.label',
    'help_text': 'helpText',
    'default_logo_alt': 'defaultLogoAlt'
  } %}
{%- for lang, settings in shibds_settings.language_bundles|dictsort %}
{%- if loop.first %}
    this.langBundles = {
{%- endif %}
        '{{ lang }}' = {
{%- for setting, value in settings|dictsort %}
            '{{ language_bundle_setting_map[setting] }}': '{{ value }}'
{%- if not loop.last -%}
            ,
{%- endif %}
{%- endfor %}
          }
{%- if loop.last %}
      };
{%- else -%}
        ,
{%- endif %}
{%- else %}
    //this.langBundles = {
    //  'en': {
    //    'fatal.divMissing': '<div> specified  as "insertAtDiv" could not be located in the HTML',
    //    'fatal.noXMLHttpRequest': 'Browser does not support XMLHttpRequest, unable to load IdP selection data',
    //    'fatal.wrongProtocol' : 'Policy supplied to DS was not "urn:oasis:names:tc:SAML:profiles:SSO:idpdiscovery-protocol:single"',
    //    'fatal.wrongEntityId' : 'entityId supplied by SP did not match configuration',
    //    'fatal.noData' : 'Metadata download returned no data',
    //    'fatal.loadFailed': 'Failed to download metadata from ',
    //    'fatal.noparms' : 'No parameters to discovery session and no defaultReturn parameter configured',
    //    'fatal.noReturnURL' : "No URL return parameter provided",
    //    'fatal.badProtocol' : "Return request must start with https:// or http://",
    //    'idpPreferred.label': 'Use a suggested selection:',
    //    'idpEntry.label': 'Or enter your organization\'s name',
    //    'idpEntry.NoPreferred.label': 'Enter your organization\'s name',
    //    'idpList.label': 'Or select your organization from the list below',
    //    'idpList.NoPreferred.label': 'Select your organization from the list below',
    //    'idpList.defaultOptionLabel': 'Please select your organization...',
    //    'idpList.showList' : 'Allow me to pick from a list',
    //    'idpList.showSearch' : 'Allow me to specify the site',
    //    'submitButton.label': 'Continue',
    //    'helpText': 'Help',
    //    'defaultLogoAlt' : 'DefaultLogo'
    //  }
    //};
{%- endfor %}

    this.maxPreferredIdPs = {{ shibds_settings.max_preferred_idps }};
    this.maxIdPCharsButton = {{ shibds_settings.max_idp_chars_button }};
    this.maxIdPCharsDropDown = {{ shibds_settings.max_idp_chars_dropdown }};
    this.maxIdPCharsAltTxt = {{ shibds_settings.max_idp_chars_alt_text }};

    this.minWidth = {{ shibds_settings.min_width }};
    this.minHeight = {{ shibds_settings.min_height }};
    this.maxWidth = {{ shibds_settings.max_width }};
    this.maxHeight = {{ shibds_settings.max_height }};
    this.bestRatio = {{ shibds_settings.best_ratio }};
}

/* IDPSELECT_CONFIG.JS ends here. */
