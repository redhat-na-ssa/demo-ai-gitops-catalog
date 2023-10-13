#!/bin/bash

demo_default(){
  selected=bootstrap/default
  
  ocp_control_nodes_schedulable
  local_argocd "${selected}"

}
