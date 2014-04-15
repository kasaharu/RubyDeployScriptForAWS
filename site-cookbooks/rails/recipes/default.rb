#
# Cookbook Name:: rails
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
log "Prepare Rails"

#bash "install ruby and rails" do
#  code <<-EOS
#    /home/ubuntu/.rbenv/bin/rbenv install 2.0.0-p0
#    /home/ubuntu/.rbenv/bin/rbenv rehash
#    /home/ubuntu/.rbenv/bin/rbenv global 2.0.0-p0
#    gem update --system
#    gem install rails
#  EOS
#end

bash "rails install" do
  code <<-EOC
    export PATH="/home/vagrant/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    gem update --system
    gem install rails
  EOC
end

