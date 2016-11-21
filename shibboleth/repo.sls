{% set repo_url =
    'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_%s'|format(grains['osmajorrelease'])
      if grains['os'] in ['CentOS', 'RedHat']
      and grains['osmajorrelease'] >= 7 else
    'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_CentOS-6'
      if grains['os'] == 'CentOS'
      and grains['osmajorrelease'] == 6 else
    'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_5'
      if grains['os'] == 'CentOS'
      and grains['osmajorrelease'] == 5 else
    'http://download.opensuse.org/repositories/security:/shibboleth/RHEL_%s'|format(grains['osmajorrelease'])
      if grains['os'] == 'RedHat'
      and grains['osmajorrelease'] <= 6 else
    'http://download.opensuse.org/repositories/security:/shibboleth/SLE_%s'|format(grains['osrelease'].replace(' ', '_'))
      if grains['os'] == 'SUSE' else
    'http://download.opensuse.org/repositories/security:/shibboleth/openSUSE_%s'|format(grains['osrelease'].replace(' ', '_'))
      if grains['os'] == 'openSUSE' else
    'deb http://pkg.switch.ch/switchaai/%s %s main'|format(grains['os']|lower, grains['oscodename'])
      if grains['os'] in ['Debian', 'Ubuntu'] else
    False
  %}

{% if repo_url and grains['os_family'] in ['RedHat', 'Suse'] %}
shib_repo:
  pkgrepo.managed:
    - name: security_shibboleth
    - humanname: Shibboleth ({{ '%s_%s'|format(grains['os'], grains['osmajorrelease']) }})
    - baseurl: {{ repo_url|yaml_encode }}
    - gpgkey: {{'%s/repodata/repomd.xml.key'|format(repo_url)|yaml_encode }}
    - gpgcheck: 1

{% elif repo_url and grains['os_family'] in ['Debian', 'Ubuntu'] %}
shib_repo:
  pkgrepo.managed:
    - file: /etc/apt/sources.list.d/SWITCHaai-swdistrib.list
    - name: {{ repo_url|yaml_encode }}
    - key_url: http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc

{% endif %}
