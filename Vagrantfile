Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "quicknotes-vm"
  
  config.vm.network "forwarded_port", 
    guest: 8080, 
    host: 18080, 
    host_ip: "127.0.0.1"
  
  config.vm.synced_folder "./app", "/home/vagrant/app"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end
  
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y wget curl
    
    wget https://go.dev/dl/go1.24.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.24.5.linux-amd64.tar.gz
    echo 'export PATH=/usr/local/go/bin:$PATH' >> /home/vagrant/.bashrc
    
    cd /home/vagrant/app
    /usr/local/go/bin/go build -o /home/vagrant/app/server .
    nohup /home/vagrant/app/server > /home/vagrant/server.log 2>&1 &
    
    echo "Server started on port 8080"
  SHELL
end
