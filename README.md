Portdowngrade
=============

Downgrade a port in the FreeBSD ports tree

Interactively view and choose a port version and revert the ports dir in the ports tree.

### Requirements

1. shells/bash
1. devel/subversion
1. devel/git (with SVN option)
1. security/sudo

### Usage

    portdowngrade.sh <origin/portname>

For example,

    portdowngrade.sh devel/gitolite

Motivation
-----------

The original [portdowngrade](http://portdowngrade.sourceforge.net/) <= 1.0 does not support the SVN ports repository. [ports-mgmt/portdowngrade](http://www.freshports.org/ports-mgmt/portdowngrade/) >= 1.0 now has support for SVN.
