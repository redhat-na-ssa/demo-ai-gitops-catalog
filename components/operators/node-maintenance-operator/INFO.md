# node-maintenance-operator

Node Maintenance Operator (NMO)

This operator will keep nodes cordoned and drained while a matching NodeMaintenance (nm) custom resource exists.
This is useful when investigating problems with a machine, or performing an operation on the underlying machine that might result in node failure.
