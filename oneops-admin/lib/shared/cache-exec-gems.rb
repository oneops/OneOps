#!/usr/bin/env ruby
require 'optparse'
require 'yaml'
Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'exec-order','*.rb')].each {|f| require f }

# set cwd to same dir as the cache-exec-gems.rb file
Dir.chdir File.dirname(__FILE__)

log_level = "debug"
gem_sources  = get_gem_sources
config_files = [get_file_from_parent_dir('exec-gems.yaml'), get_file_from_parent_dir('exec-gems-az.yaml')]

config_files.each do |config_file|

  puts "parsing config_file #{config_file}"

  gem_config = YAML::load(File.read(config_file))
  gem_config.keys.each do |impl|
    dsl, version = impl.split('-')
    puts "dsl=#{dsl}, version=#{version}"
    case dsl
      when "chef"
        if (version != "12.11.18")
          gem_list = get_gem_list(dsl, version, config_file.split('/').last)
          gen_gemfile_and_install(gem_sources, gem_list, log_level, 'package')

          if File.exists?('Gemfile')
            File.delete('Gemfile')
          end
          if File.exists?('Gemfile.lock')
            File.delete('Gemfile.lock')
          end
        else
          puts "skipping packaging gems for chef 12.11.18"
        end
    end
  end
end



