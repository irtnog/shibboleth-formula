.. _readme:

shibboleth-formula
==================

|img_travis| |docs| |img_sr|

.. |img_travis| image:: https://travis-ci.com/irtnog/shibboleth-formula.svg?branch=master
   :alt: Travis CI Build Status
   :scale: 100%
   :target: https://travis-ci.com/irtnog/shibboleth-formula
.. |docs| image:: https://readthedocs.org/projects/docs/badge/?version=latest
   :alt: Documentation Status
   :scale: 100%
   :target: https://shibboleth-formula.readthedocs.io/en/latest/?badge=latest
.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release

This Salt state formula installs and configures `Shibboleth <http://shibboleth.net/>`_, a free and open-source federated identity solution that provides Single Sign-On capabilities and allows sites to make informed authorization decisions for individual access of protected online resources in a privacy-preserving manner.

.. contents:: **Table of Contents**

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

Contributing to this repo
-------------------------

**Commit message formatting is significant!!**

Please see :ref:`How to contribute <CONTRIBUTING>` for more details.

Available states
----------------

.. contents::
   :local:

``shibboleth.repo``
^^^^^^^^^^^^^^^^^^^

This state installs either the OpenSUSE Build Service (on CentOS/RHEL/SUSE) or the SWITCHaai (on Debian/Ubuntu) binary package repositories.

``shibboleth.idp``
^^^^^^^^^^^^^^^^^^

This state installs and configures the Shibboleth Identity Provider (IdP).
Currently, only very simple attribute generation and attribute release rules are supported.
  
``tomcat.shibboleth-idp``
^^^^^^^^^^^^^^^^^^^^^^^^^

This state deploys the Shibboleth IdP using Tomcat.
It requires `tomcat-formula <https://github.com/saltstack-formulas/tomcat-formula>`_.

``shibboleth.mda``
^^^^^^^^^^^^^^^^^^

This state installs, configures, and runs the CLI version of the Shibboleth Metadata Aggregator (MA a/k/a MDA).
On supported versions of Unix/Linux, this also creates a cron(8) job to refresh the generated metadata aggregates on an hourly basis.

``shibboleth.sp``
^^^^^^^^^^^^^^^^^

This state installs and configures the Shibboleth Service Provider (SP).

``shibboleth.ds``
^^^^^^^^^^^^^^^^^

This state installs and configures the Shibboleth Embedded Discovery Service (EDS).

``xmlsectool``
^^^^^^^^^^^^^^

This state installs and configures xmlsectool, and signs SAML metadata specified in Pillar data.

