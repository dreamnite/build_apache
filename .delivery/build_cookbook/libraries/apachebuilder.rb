## Helper modules for the build cookbook
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

module ApacheBuild
  module DSL ## Set up a module with helpers we need across the different recipes.
    def ab_load_config(config_file) ## Load in and parse the specified JSON config
      conf_file = "#{workflow_workspace_repo}/#{config_file}"
      JSON.parse(File.read(conf_file)) # Read and parse the config file
    end
  end
end
# Make it available for use in the major areas, recipes during compile, resources (like inside a ruby_block), and for providers.
Chef::Recipe.send(:include, ApacheBuild::DSL)
Chef::Resource.send(:include, ApacheBuild::DSL)
Chef::Provider.send(:include, ApacheBuild::DSL)
