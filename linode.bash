#!/bin/bash

setup_user() {
    if [[ -e /home/"$username" ]]; then
       echo "$username is already being used!"
    else
      echo "$username is not taken!"
      adduser $username
      adduser $username sudo
    fi
}

get_dependencies() {
    sudo apt update
    sudo apt upgrade -y 
    sudo apt autoremove -y 
    # Currently install python2/3, pip, tmux, vim, zsh, sqlite3, postgresql, golang, nodejs as well as other get_dependencies
    PACKAGE_LIST="curl software-properties-common tmux git vim zsh gnupg2 sqlite3 postgresql less python3 python3-pip python-dev python3-dev python-pip ufw pry ack-grep libfuse2 fuse python3-neovim build-essential bison zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libffi-dev nodejs apt-transport-https ca-certificates golang oracle-java8-installer make gcc"

    for item in $PACKAGE_LIST; do
      sudo apt -y install $item
    done
}

add_repos() {
    sudo apt-add-repository -y ppa:neovim-ppa/stable
    sudo apt-add-repository -y ppa:zanchey/asciinema
    yes "\n" | sudo add-apt-repository ppa:keithw/mosh
    #Instructions straight from https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    yes "\n" | sudo add-apt-repository -y \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"

    yes "\n" | sudo add-apt-repository -y ppa:webup8team/java

    sudo apt update
}

install_added_repos() {
   sudo apt install -y neovim
   sudo apt install -y asciinema
   sudo apt install -y docker-ce
   sudo apt install -y mosh
}

set_git_config() {
    # setup git
    git config --global user.name "$username" 
    git config --global user.email "$email"
    echo "setting git global username to $username"
    echo "setting git global email to $email"
    echo "if you would like to change this later, go to ~/.gitconfig or by using git config --global user.name 'name'"
}

install_tmux_plugin_manager(){
    # add tmux plugin manager
    if [[ ! -e "$HOME_DIR/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        echo 'Tmux plugins already installed!'
    fi
}

change_default_editor_to_nvim() {
    # update editor
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    yes "0" | sudo update-alternatives --config editor
}

install_neovim_stuff() {
    # update python3 & python2 - neovim
    sudo -H pip2 install neovim 
    sudo -H pip3 install neovim 
    # Install neovim-npm
    yes "\n" | npm install -g neovim
}

ufw_connection_setup(){
    ## enabling traffic
    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow http/tcp

    # configure server to accept mosh connections
    sudo ufw allow port 60000:61000 proto udp

    # enable firewall
    sudo ufw enable
}

setup_docker() {
    # Configure docker
    groupadd docker
    usermod -aG docker $username
}
# install chruby
install_chruby() {
    if [[ -e /usr/local/share/chruby/chruby.sh ]]; then
        echo 'chruby is already installed'
    else
        
        wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
        tar -xzvf chruby-0.3.9.tar.gz
        cd chruby-0.3.9/
        sudo make install
    fi
}

#install ruby-install
install_ruby_install() {
    if [[ $"(command -v ruby-install)" ]]; then 
        echo 'ruby-install is already installed'
    else
        wget -O ruby-install-0.7.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz
        tar -xzvf ruby-install-0.7.0.tar.gz
        cd ruby-install-0.7.0/
        sudo make install 
    fi
}

install_and_set_ruby_version() {
    # install ruby
    ruby-install ruby-2.5.1 --no-reinstall # will not install if 2.5.1 already detected
    echo "ruby-2.5.1" > ~/.ruby-version # Sets current working ruby version to 2.5.1
}

install_gems() {
    # install gems
    if [[ ! -e "$GEMS_DIR" ]]; then
        mkdir -p "$GEMS_DIR"
        echo "No gem directory found. Creating a gem directory @ $GEMS_DIR"
    else
        echo "$GEMS_DIR already exists, installing to this directory."
    fi

    GEM_LIST="bundler rails colorls neovim rake sinatra solargraph"

    for gem_name in "$GEM_LIST"; do
        gem install $gem_name --install-dir "$GEMS_DIR"
    done
}
# Install zsh and accompanying plugins

# checks if ohmyzsh already installed
install_oh_my_zsh() {
    if [[ ! -e "$HOME_DIR/.oh-my-zsh" ]]; then
        git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
        chsh -s /bin/zsh
    else
        echo "ohmyzsh already installed"
    fi
}


install_zsh_autosuggestions() {
    #checks if autosuggestions exists
    if [[ ! -e "$ZSH_PLUGINS/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
    else
        echo 'zsh-autosuggestions already exists'
    fi
}

install_zsh_syntax_highlighting() {
    # check if syntax highlighting already installed
    if [[ ! -e "$ZSH_PLUGINS/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS/zsh-syntax-highlighting"
    else
        echo 'zsh-syntax-highlighting already exists'
    fi
}


install_powerlevel9k() {
    # Check if powerlevel9k already installed
    if [[ ! -e "$ZSH_THEMES/powerlevel9k" ]]; then
        git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
    else
        echo 'Powerlevel9k already exists'
    fi
}


symlink_dotfiles() {
    # Runs the change.bash file provided in vps-setup which this file is cloned from
    if [ -e "$DOTFILES" ]; then
        source "$DOTFILES"
    else
        echo "$DOTFILES does not exist. Run change.bash to transfer over dotfiles." 
    fi
}

runs_with_user_and_email(){
    runs_with_user_only
    set_git_config
}

runs_with_user_only(){
    get_dependencies
    add_repos
    install_added_repos
    ufw_connection_setup
    change_default_editor_to_nvim
    install_neovim_stuff
    install_tmux_plugin_manager
    setup_docker
    install_chruby
    install_ruby_install
    install_and_set_ruby

    install_gems
    install_oh_my_zsh
    install_zsh_autosuggestions
    install_zsh_syntax_highlighting
    symlink_dotfiles
    # sourcing other files
    source "$HOME_DIR/vps-setup/secure_server.bash"
}

cd ~
username=""
email=""
HOME_DIR="/home/$username"
DOTFILES="$HOME_DIR/vps-setup/change.bash"
GEMS_DIR="$HOME_DIR/.gem/ruby/2.5.1"
ZSH_PLUGINS="$HOME_DIR/.oh-my-zsh/custom/plugins"
ZSH_THEMES="$HOME_DIR/.oh-my-zsh/custom/themes"

# :: - optional
# : - required optional
# nothing - semi-flag

# set an initial value for the flag
username=
email=

OPTS=`getopt -o e:u: --long email:,username: -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "echo Script Usage: linode.bash [-e|--email=email (optional)]  [-u|--username=name (required)]." >&2 ; exit 1 ; fi

echo "$OPTS"
eval set -- "$OPTS"

while true; do
  case "$1" in
      -e | --email ) email="$2"; shift 2;;
      -u | --username ) username="$2"; shift 2 ;;
      -- ) shift; break ;;
      * ) echo "echo Script Usage: linode.bash [-e|--email=email (optional)]  [-u|--username=name (required)]." ; exit 1 ;;
  esac
done
# checks for no exit errors of last comand
if [[ $? != 0 ]] ; then echo "Internal error" >&2 ; exit 1 ; fi
# do something with the variables -- in this case the lamest possible one :-)
echo "username = $username"
echo "email = $email"

if [[ -z "$username" ]]; then
    echo "No arguments were passed to -u"
    echo "Set username by running sudo bash linode.bash -u foo or"
    echo "by using --username=foo"
    echo "Exiting."
    exit 3
fi
 
setup_user

if [[ -z "$email" ]]; then
    echo "Email not given. Set git config --global user.email to fix the only command not run"
    runs_with_user_only
else
    runs_with_user_and_email
fi
