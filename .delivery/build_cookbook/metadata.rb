name 'build_cookbook'
maintainer 'Jp Robinson'
maintainer_email 'you@example.com'
license 'all_rights'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)
depends 'delivery-sugar'