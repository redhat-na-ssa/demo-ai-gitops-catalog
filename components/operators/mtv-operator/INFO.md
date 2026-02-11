# mtv-operator

The Migration Toolkit for Virtualization Operator manages the deployment and life cycle of Migration Toolkit for Virtualization on [OpenShift](https://www.openshift.com/) Container Platform.

### Installation

OpenShift Virtualization must be installed on an OpenShift migration target cluster before you can use MTV to transfer any VMs to that cluster

Once you have successfully installed the Operator, proceed to deploy components by creating the required ForkliftController CR.

By default, the Operator installs the following components on a target cluster:

* Controller, to coordinate migration processes.
* UI, the web console to manage migrations.
* Validation, a service to validate migration workflows.

### Compatibility

Migration Toolkit for Virtualization 2.9 is supported on OpenShift 4.17, 4.18 and 4.19

Migration Toolkit for Virtualization 2.10 is supported on OpenShift 4.18, 4.19 and 4.20

More information on compatibility in the [MTV Lifecycle document](https://access.redhat.com/support/policy/updates/migration-toolkit-for-virtualization).

### Documentation
Documentation can be found on the [Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/migration_toolkit_for_virtualization/).

### Getting help
If you encounter any issues while using Migration Toolkit for Virtualization Operator, create a [support case](https://access.redhat.com/support/cases/) for bugs, enhancements, or other requests.

### Contributing
You can contribute by:

* Creating a case in the [Red Hat Customer Portal](https://access.redhat.com/support/cases/) with any issues you find using Migration Toolkit for Application and its Operator.
* Fixing issues by opening Pull Requests in the [KubeV2V](https://github.com/kubev2v/) under Forklift Projects.
* Improving Forklift upstream [documentation](https://github.com/kubev2v/forklift-documentation/).
