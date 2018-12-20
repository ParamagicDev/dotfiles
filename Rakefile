# frozen_string_literal: true

require 'rake/testtask'

BACKUP_DIR = File.join(Dir.home, 'backup')
CONFIG_DIR = File.join(__dir__, 'config')

task default: %w[test]

desc 'Runs tests'
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/test*.rb']
  end
end

directory BACKUP_DIR

desc "copies files from config dir to home dir, will place existing dotfiles into #{BACKUP_DIR}"
task copy_config: [BACKUP_DIR] do
  FileList.new(Dir.children('config')).each do |file|
    dot_file = File.join(Dir.home, ".#{file}")
    backup_file = File.join(BACKUP_DIR, "#{dot_file}.orig")

    if dot_file_not_found?(dot_file) || backup_file_found?(backup_file)
      cp(dot_file, backup_file)
    end

    cp(file, dot_file) # Then, sends the copies dot_file from config to home
  end
end

private

def dot_file_not_found?(file)
  return false if File.exist?(file)

  puts "#{file} does not exist. No backup created."
  true
end

def backup_file_found?(file)
  return true if File.exist?(file)

  puts "#{file} exists already. No backup created."
  false
end
