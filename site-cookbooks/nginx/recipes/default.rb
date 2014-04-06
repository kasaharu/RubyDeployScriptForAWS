#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

############################## apt-get update

log "Run apt-get update..."
execute "apt-get update" do
  action :run
end
log "apt-get update Done!!!"

############################## git install

log "Git install ..."
%w{libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

package "git-core" do
  action :install
end
log "Git install Done!!!"

############################## nginx install

log "Nginx install ..."
package "nginx" do
  action :install
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable , :start ]
end
log "Nginx install Done!!!"

