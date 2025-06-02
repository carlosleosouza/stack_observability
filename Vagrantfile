Vagrant.configure("2") do |config|
  # Lista de nodes Linux
  nodes = [
    { :hostname => "node1",  :ip => "192.168.56.11" },
   # { :hostname => "node2",  :ip => "192.168.56.12" },
   # { :hostname => "node3",  :ip => "192.168.56.13" }
  ]

  # Box padrão para nodes Linux
  config.vm.box = "ubuntu/jammy64"

  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.hostname = node[:hostname]
      node_config.vm.network "private_network", ip: node[:ip]
#      node_config.vm.network "public_network", bridge: "wlp0s20f3"
      node_config.vm.network "forwarded_port", guest: 30080, host: 30080
      node_config.vm.network "forwarded_port", guest: 30081, host: 30081
      node_config.vm.network "forwarded_port", guest: 30082, host: 30082
      node_config.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 2
      end
    end
  end
end
