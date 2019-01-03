# frozen_string_literal: true

module VpsSetup
  class Setup
    def self.privileged_user?
      Process.uid.zero?
    end

    def self.root?
      privileged_user && Dir.home == '/root'
    end

    def self.add_user(name = nil)
      name ||= retrieve_name

      if Dir.exist?("/home/#{name}")
        puts "#{name is already taken}"
        return :name_taken
      end

      #######################################
      #  This only works on a ubuntu system #
      #######################################
      # creates user
      Rake.sh("adduser #{name}")
      # makes a user a sudo user by adding them to the sudo group
      Rake.sh("adduser #{name} sudo")
    end

    # This will swap the user and exit the program
    def self.swap_user(name = nil)
      #######################################
      #  This only works on a ubuntu system #
      #######################################
      name ||= retrieve_name

      # changes user to the provided name. Will prompt for password
      begin
        Rake.sh("su #{name}")
      rescue
        puts "Something went wrong. Please reenter your password:"
        retry
      else
        puts "Authentication successful"
      end
    end


    def self.retrieve_name
      puts "Please enter a username to be used:"
      gets.chomp
    end

    def self.add_repos
      # neovim repo
      Rake.sh('sudo apt-add-repository -y ppa:neovim-ppa/stable')
      # asciinema repo for recording the terminal
      Rake.sh('sudo apt-add-repository -y ppa:zanchey/asciinema')
      # mosh repo
      Rake.sh(%(yes "\n" | sudo add-apt-repository ppa:keithw/mosh))

      # Instructions straight from https://docs.docker.com/install/linux/docker-ce/ubuntu/#set-up-the-repository
      # Docker repo
      Rake.sh('curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -')
      Rake.sh('sudo apt-key fingerprint 0EBFCD88')
      Rake.sh(%{yes "\n" | sudo add-apt-repository -y \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
             $(lsb_release -cs) \
             stable"})
      # yarn repo
      Rake.sh('curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -')
      Rake.sh(%(echo "deb https://dl.yarnpkg.com/debian/ stable main"
             | sudo tee /etc/apt/sources.list.d/yarn.list))

      Rake.sh('sudo apt update')
    end
  end
end
# namespace :setup do
#   task :ubuntu, [:username] => %i[swap_user apt_all add_other_tools ruby_install] do |_t, args|
