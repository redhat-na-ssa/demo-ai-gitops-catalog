# cincinnati-operator

# Use Case
Running an Update Service instance in a cluster is appealing for offline OpenShift
clusters or for admins that want to provide their own graph data instead of
using [https://github.com/openshift/cincinnati-graph-data](https://github.com/openshift/cincinnati-graph-data/).

# About Update Service
Update Service uses **Cincinnati** which is an update protocol designed to facilitate
automatic updates. It describes a particular method for representing transitions between
releases of a project and allowing a client to perform automatic updates between these
releases.

## Components
A **Graph Builder** iterates over the release payloads hosted by the
storage component and builds a DAG of the releases. It is responsible for
verifying that the graph described by the releases is acyclic and connected.

A **Policy Engine** is in charge of altering a client's view of the graph
by applying a set of filters which are defined within the particular Policy
Engine instance. Both the input to and the output from Policy Engines is a
graph, allowing multiple Policy Engines to be chained together. The first
Policy Engine in a chain will fetch its graph from the Graph Builder and the
last Policy Engine in a chain will serve the modified graph to the client.

An **Update Service client** is the end consumer of the release payloads. The
client periodically queries the Policy Engine for updates and applys them if
available.

# Query OpenShift's Update Service Endpoint
$ curl --silent --header 'Accept:application/json' 'https://api.openshift.com/api/upgrades_info/v1/graph?arch=amd64&channel=stable-4.2' | jq '. as $graph | $graph.nodes | map(.version == "4.2.13") | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.])'