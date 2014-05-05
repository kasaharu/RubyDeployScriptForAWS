#
# Cookbook Name:: ruby
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
log "Prepare Ruby"

package "ruby" do
  action :purge
end

%w{build-essential curl zlib1g-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev sqlite3 libsqlite3-dev nodejs make gcc ncurses-dev libgdbm-dev libdb4.8-dev libffi-dev tk-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

git "/home/vagrant/.rbenv" do
  repository "git://github.com/sstephenson/rbenv.git"
  reference "master"
  action :sync
  user "vagrant"
  group "vagrant"
end


%w{/home/vagrant/.rbenv/plugins}.each do |dir|
  directory dir do
    action :create
    user "vagrant"
    group "vagrant"
  end
end

git "/home/vagrant/.rbenv/plugins/ruby-build" do
  repository "git://github.com/sstephenson/ruby-build.git"
  reference "master"
  action :sync
  user "vagrant"
  group "vagrant"
end

log "ruby checkout done"


bash "insert_line_rbenvpath" do
  code <<-EOS
    echo 'export PATH="/home/vagrant/.rbenv/bin:$PATH"' >> /home/vagrant/.bashrc && source /home/vagrant/.bashrc
    echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc
  EOS
end

bash "install ruby" do
  user "vagrant"
  group "vagrant"
  code <<-EOS
    /home/vagrant/.rbenv/bin/rbenv install 2.0.0-p0
    /home/vagrant/.rbenv/bin/rbenv rehash
    /home/vagrant/.rbenv/bin/rbenv global 2.0.0-p0
  EOS
end


