#
# Cookbook:: build_cookbook
# Recipe:: unit
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

# Our unit for approval is that the code must compile. Failed compliation, no reason to move on.
include_recipe 'build_cookbook::setup_build' # Set up the workspace
include_recipe 'build_cookbook::perform_build' # Compile
