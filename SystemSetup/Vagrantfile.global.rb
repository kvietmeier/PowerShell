# -*- mode: ruby -*-
# vi: set ft=ruby :

# Alternate proxies
#config.proxy.http     = "http://proxy.foobar.com:911"
#config.proxy.https    = "https://proxy.foobar.com:912"

# Put global settings in here
Vagrant.configure("2") do |config|

  # Set some global variables like SSH Keys
  $adminvm_karlvkey = File.readlines("#{Dir.home}/repos/certs/adminvm_karlv_id_rsa.pub").first.strip
  $adminvm_rootkey = File.readlines("#{Dir.home}/repos/certs/adminvm_root_id_rsa.pub").first.strip
  $defaultvm_CPU="1"
  $defaultvm_MEM="512"

  # Proxies check to see if they are set
  if File.readlines("C:/Users/ksvietme/.setproxies").grep(/True/).any?
    config.proxy.http     = "http://proxy.foobar.com:911"
    config.proxy.https    = "https://proxy.foobar.com:912"
    config.proxy.no_proxy = "localhost,127.0.0.1,*.mylocaldomain.com,172.10.0.0/24,172.16.0.0/24"
  end
  
end  
