
#check for ubuntu 

cat /etc/issue|grep "Ubuntu 12.04" > /dev/null
if [ $? -eq 0 ];
then
  echo "Installing Chef Server on Ubuntu 12.04 LTS"
  echo "deb http://apt.opscode.com/ precise-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
  sudo mkdir -p /etc/apt/trusted.gpg.d
  gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
  gpg --export packages@opscode.com |sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null

  sudo apt-get -y update

  sudo apt-get -y install opscode-keyring

  sudo apt-get -y upgrade
  sudo apt-get -y install debconf-utils vim expect

read -p "Please enter the new chef url, eg http://server:4000" chef_server_url
read -p "Please enter the new chef server password" chef_server_password
cat <<EOF >>/tmp/preseed.txt
# URL of Chef Server (e.g., http://chef.example.com:4000):
chef    chef/chef_server_url    string  $chef_server_url
# New password for the 'admin' user in the Chef Server WebUI:
chef-server-webui       chef-server-webui/admin_password        password       $chef_server_password 
# New password for the 'chef' AMQP user in the RabbitMQ vhost "/chef":
chef-solr       chef-solr/amqp_password password        chefSrvr
EOF

cat /tmp/preseed.txt


  sudo debconf-set-selections /tmp/preseed.txt
  rm /tmp/preseed.txt
  sudo apt-get -y install chef chef-server

  # install the knife openstack plugin
  sudo apt-get -y install libxml2-dev libxslt-dev

  mkdir -p ~/.chef
  sudo cp /etc/chef/validation.pem /etc/chef/webui.pem ~/.chef
  sudo chown -R $(id -un) ~/.chef
  rm -f /home/eedgar/.chef/knife.rb

  cd /tmp
  rm -rf fog
  git clone git://github.com/mattray/fog.git
  cd fog
  sudo gem build fog.gemspec
  sudo gem install fog-1.3.1.gem --no-doc --no-ri

  cd /tmp
  rm -rf knife-openstack
  git clone -b 0.6.0 git://github.com/mattray/knife-openstack.git
  cd knife-openstack
  sudo gem build knife-openstack.gemspec
  sudo gem install knife-openstack-0.6.0.gem --no-doc --no-ri

  # install librarian

  gem install librarian



  /usr/bin/expect <<EOD
spawn knife configure -i -s http://192.168.1.105:4000 -u $(id -un) -r /home/chef/repos
expect "config file"
send "\n"
expect "admin clientname"
send "\n"
expect "admin client's private key"
send "/home/$(id -un)/.chef/webui.pem\n"
expect "validation clientname"
send "\n"
expect "validation key"
send "/home/$(id -un)/.chef/validation.pem\n"
expect eof
EOD

echo 

else
  echo "This script is not tested against your Version of the Operating System"
  exit 1
fi


# sudo apt-get install debconf-utils
# sudo debconf-get-selections > file

# http://jtimberman.housepub.org/blog/2012/03/25/knife-config-plugin/

# Create a custom ruby knife.rb file to switch between openstack installs
