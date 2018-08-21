# dotfiles

# Usage

    clone the repo
    cd ~/path/to/dotfiles
    sudo chmod +x ./amazon-ec2-install.bash
    sudo ./amazon-ec2-install.bash
    
    or 
    
    cd ~/path/to/dotfiles
    sudo bash amazon-ec2-install.bash
# updates
    update .tmuxrc
    update .vimrc
    possibly fix zsh? works fine at this point
    
# Updating amazon ec2 instance as text

    sudo yum install git -y
    git clone https://github.com/ParamagicDev/vps-setup.git
    sudo bash ~/ec2setup/amazon-ec2-install.bash
  
# Updating linode instance

    sudo apt install git
    git clone https://github.com/ParamagicDev/vps-setup.git
    sudo bash ~/vps-setup/linode.bash
