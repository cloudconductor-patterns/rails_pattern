#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'find'
require 'open3'

class UserActionBase

    def initialize(script_role, script_event)
        @path_dictionary = {
            cloudconductor_root_path: '/opt/cloudconductor',
            parameters_file_name: 'parameters.json',
            pattern_root_path: '/opt/cloudconductor/patterns',
            temp_directory_name: 'temp',
            log_directory_name: 'logs',
            log_file_name: 'chef-solo.log',
            log_level: 'info',
            file_cache_directory_name: 'cache',
            config_file_name: 'solo.rb',
            node_file_name: 'node.json'
        }
        @roles = ENV['SERF_TAG_ROLE'].split(',')
        @script_role = script_role
        @script_event = script_event
    end

    def create_config_file()
        File.open(@path_dictionary[:config_file_path], 'w') do |file|
            file.write "role_path '%{role_file_path}'\n" % @path_dictionary
            file.write "log_level :%{log_level}\n" % @path_dictionary
            file.write "log_location '%{log_path}/#{@script_role}_%{log_file_name}'\n" % @path_dictionary
            file.write "file_cache_path '%{file_cache_path}'\n" % @path_dictionary
            file.write "cookbook_path ['%{cookbooks_path}', '%{site_cookbooks_path}']\n" % @path_dictionary
        end
    end

    def fetch_node_attributes
        parameters = {}
        begin
            parameters = open("%{cloudconductor_root_path}/%{parameters_file_name}" % @path_dictionary) do |io|
                JSON.load(io)
            end
        rescue
        end
        parameters
    end

    def create_run_list
        ["role[#{@script_role}_#{@script_event}]"]
    end

    def create_node_file
        node_data = fetch_node_attributes
        node_data[:run_list] = create_run_list
        File.open(@path_dictionary[:node_file_path], 'w') do |file|
          file.write node_data.to_json
        end
    end

    def prepare_path pattern_path
        @path_dictionary[:pattern_path] = pattern_path
        @path_dictionary[:temp_path] = "%{pattern_path}/%{temp_directory_name}" % @path_dictionary
        @path_dictionary[:config_file_path] = "%{temp_path}/%{config_file_name}" % @path_dictionary
        @path_dictionary[:node_file_path] = "%{temp_path}/%{node_file_name}" % @path_dictionary
        @path_dictionary[:log_path] = "%{temp_path}/%{log_directory_name}" % @path_dictionary
        @path_dictionary[:file_cache_path] = "%{temp_path}/%{file_cache_directory_name}" % @path_dictionary
        @path_dictionary[:chef_repo_path] = "%{pattern_path}/resources/chef-repo" % @path_dictionary
        @path_dictionary[:role_file_path] = "%{chef_repo_path}/roles" % @path_dictionary
        @path_dictionary[:cookbooks_path] = "%{chef_repo_path}/cookbooks" % @path_dictionary
        @path_dictionary[:site_cookbooks_path] = "%{chef_repo_path}/site-cookbooks" % @path_dictionary
        FileUtils.mkdir_p(@path_dictionary[:log_path])
        FileUtils.mkdir_p(@path_dictionary[:file_cache_path])
    end

    def target?
        @roles.include? @script_role
    end

    def exec
        return if !target?
        Dir.entries(@path_dictionary[:pattern_root_path]).select do |entry|
            path = File.join(@path_dictionary[:pattern_root_path], entry)
            if (File.directory? path) and !((entry =='.') || (entry == '..')) then
                prepare_path path
                create_config_file
                create_node_file
                out, err, status = Open3.capture3("cd %{chef_repo_path}; berks vendor ./cookbooks" % @path_dictionary)
                out, err, status = Open3.capture3("chef-solo -c %{config_file_path} -j %{node_file_path}" % @path_dictionary)
            end
        end
    end
end
