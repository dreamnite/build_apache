#
# Cookbook:: build_cookbook
# Recipe:: unit
#
# Copyright:: 2017, Jp Robinson .
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Our unit for approval is that the code must compile. Failed compliation, no reason to move on.
include_recipe 'build_cookbook::setup_build' # Set up the workspace
include_recipe 'build_cookbook::perform_build' # Compile
