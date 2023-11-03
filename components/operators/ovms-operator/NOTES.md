# Notes

It would appear there are several messages when building this image.

The quickstart requires a lot of context switching between infrastructure button clicking and downloading
a jupyter notebook. This is a lot of work for data scientist.

Has this been tested with someone who doesn't have cluster-admin (most data scientists will not)?

Does this really make it easier for someone to have a notebook that is "supported" by Intel?

## Notebook instances

You can create notebook CRs that create image streams compatible with RHODS.

2023-11-03

Container image not well maintained
https://github.com/openvinotoolkit/openvino_notebooks

```
Continuing in 20 seconds ...
================================================================================
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
================================================================================
SCRIPT DEPRECATION WARNING
This script, located at https://rpm.nodesource.com/setup_X, used to
install Node.js is deprecated now and will eventually be made inactive.
Please visit the NodeSource distributions Github and follow the
instructions to migrate your repo.
https://github.com/nodesource/distributions
The NodeSource Node.js Linux distributions GitHub repository contains
information about which versions of Node.js and which Linux distributions
are supported and how to install it.
https://github.com/nodesource/distributions
SCRIPT DEPRECATION WARNING
================================================================================
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
================================================================================
TO AVOID THIS WAIT MIGRATE THE SCRIPT
```
