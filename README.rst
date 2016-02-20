=============
piwik-formula
=============

.. image:: https://travis-ci.org/corux/piwik-formula.svg?branch=master
    :target: https://travis-ci.org/corux/piwik-formula

Installs the Piwik Web Analytics Software.

Available states
================

.. contents::
    :local:

``piwik``
---------

Installs the Piwik Web Analytics Software.  Includes ``piwik.selinux``, if SELinux is enabled.

``piwik.apache``
----------------

Adds a dependency to the apache formula and configures a piwik site.

``piwik.selinux``
-----------------

Configures Piwik to work with SELinux.
