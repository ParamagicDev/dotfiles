# frozen_string_literal: true

require 'test_helper'
require 'os'

TEST_CONFIG_FILES =
  %w[cygwin_zshrc
     gnome_terminal_settings
     minttyrc
     pryrc
     sshd_config
     tmux.conf
     vimrc
     zshrc].freeze

TEST_LINUX_LOCAL_DOTFILES = %w[.zshrc .pryrc .tmux.conf .vimrc].freeze
TEST_CYGWIN_LOCAL_DOTFILES = %w[.zshrc .minttyrc .pryrc .tmux.conf .vimrc].freeze

TEST_CYGWIN_CFG_DOTFILES = %w[cygwin_zshrc minttyrc pryrc tmux.conf vimrc].freeze
TEST_LINUX_CFG_DOTFILES = %w[zshrc pryrc tmux.conf vimrc].freeze

PULL_CONFIG_DIR = File.join(TEST_ROOT, 'pull_config')
PULL_LOCAL_DIR = File.join(TEST_ROOT, 'pull_test')

class TestPull < Minitest::Test
  include VpsSetup

  def setup
    rm_dirs(PULL_CONFIG_DIR, PULL_LOCAL_DIR)
    sleep(1)
    mk_dirs(PULL_CONFIG_DIR, PULL_LOCAL_DIR)

    sleep(1)
    TEST_CONFIG_FILES.each do |file|
      new_file(PULL_CONFIG_DIR, file)
    end
  end

  def new_file(dir, file_name)
    File.new(File.join(dir, file_name), 'w+')
  end

  def dir_files(dir)
    Dir.entries(dir).reject { |file| file =~ /\A\.{1,2}\Z/ }
  end

  def teardown
    rm_dirs(PULL_CONFIG_DIR, PULL_LOCAL_DIR)
    sleep(1)
  end

  def test_linux_config_dotfiles_ary
    ary = Pull.linux_config_dotfiles_ary(PULL_CONFIG_DIR)

    assert_equal(ary.sort, TEST_LINUX_CFG_DOTFILES.sort)
    # sorting doesnt matter, only used to ensure equality
    # alternatively
    # ary.each { |file| assert_includes(LINUX_CFG_DOTFILES, file) }
  end

  def test_cygwin_config_dotfiles_ary
    ary = Pull.cygwin_config_dotfiles_ary(PULL_CONFIG_DIR)

    assert_equal(ary.sort, TEST_CYGWIN_CFG_DOTFILES.sort)
  end

  def test_cygwin_local_dotfiles_ary
    TEST_CYGWIN_LOCAL_DOTFILES.each do |file|
      path = File.join(File.expand_path(PULL_LOCAL_DIR), file)
      File.new(path, 'w+')
    end

    ary = Pull.cygwin_local_dotfiles_ary(PULL_CONFIG_DIR, PULL_LOCAL_DIR)

    assert_equal(ary.sort, TEST_CYGWIN_LOCAL_DOTFILES.sort)
  end

  def test_linux_local_dotfiles_ary
    TEST_LINUX_LOCAL_DOTFILES.each do |file|
      path = File.join(File.expand_path(PULL_LOCAL_DIR), file)
      File.new(path, 'w+')
    end

    ary = Pull.linux_local_dotfiles_ary(PULL_CONFIG_DIR, PULL_LOCAL_DIR)

    assert_equal(ary.sort, TEST_LINUX_LOCAL_DOTFILES.sort)
  end

  def test_pull_sshd_config
    sshd_local_path = File.join(PULL_LOCAL_DIR, 'sshd_config')
    sshd_config_path = File.join(PULL_CONFIG_DIR, 'sshd_config')

    # prevents from writing to console to not clog up the test suite
    capture_io do
      assert_nil(Pull.pull_sshd_config(sshd_local_path, sshd_config_path))
    end
    refute(File.exist?(sshd_local_path))

    file = new_file(PULL_LOCAL_DIR, 'sshd_config')
    file.write('testing')

    Pull.pull_sshd_config(sshd_local_path, sshd_config_path)

    assert(File.exist?(sshd_config_path))
    assert(File.exist?(sshd_local_path))
    assert_equal File.read(file), File.read(sshd_config_path)
    assert_equal File.read(file), File.read(sshd_local_path)
  end

  def test_pull_gnome_term_settings
    skip('You are not running on linux, this test will fail') unless OS.linux?
    local_term = File.join(PULL_LOCAL_DIR, 'gnome_terminal_settings')
    config_term = File.join(PULL_CONFIG_DIR, 'gnome_terminal_settings')

    capture_io do
      Pull.pull_gnome_term_settings(local_term, config_term)
    end

    refute File.exist?(local_term)
    assert File.exist?(config_term)

    unless File.exist?('/org/gnome/terminal')
      skip('You do not have /org/gnome/terminal, dconf will not work')
    end

    ## ONLY WORKS IF DCONF IS INSTALLED AND GNOME TERMINAL INSTALLED
    config_file = File.new('gnome_settings')
    FileUtils.sh("dconf dump /org/gnome/terminal > #{config_file}")
    Pull.pull_gnome_term_settings(local_term, config_term)

    assert_equal File.read(local_term), File.read(config_term)
  end

  def test_pull_all_cygwin
    attr = {
      cfg_dir: PULL_CONFIG_DIR,
      local_dir: PULL_LOCAL_DIR
    }

    mk_dirs(File.expand_path(attr[:cfg_dir]))

    Dir.foreach(CONFIG_DIR) do |file|
      next if file =~ /\A\.{1,2}\Z/

      dotfile = ".#{file}"
      next unless TEST_CYGWIN_LOCAL_DOTFILES.include?(dotfile)

      dotfile_path = File.expand_path(attr[:local_dir])
      FileUtils.cp(File.join(CONFIG_DIR, file), File.join(dotfile_path, dotfile))
    end

    local_zshrc = File.join(PULL_LOCAL_DIR, '.zshrc')
    config_zshrc = File.join(PULL_CONFIG_DIR, 'cygwin_zshrc')

    refute_equal File.read(local_zshrc), File.read(config_zshrc)

    capture_io do
      Pull.pull_all_cygwin(attr)
    end

    assert_equal File.read(local_zshrc), File.read(config_zshrc)
    assert_equal dir_files(attr[:cfg_dir]).sort, dir_files(CONFIG_DIR).sort
  end
end
