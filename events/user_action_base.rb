# -*- coding: utf-8 -*-
# Copyright 2014 TIS Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'json'

class UserActionBase
  CONDUCTOR_ROOT_DIR = '/opt/cloudconductor'
  CONDUCTOR_PATTERNS_ROOT_DIR = File.join(CONDUCTOR_ROOT_DIR, 'patterns')
  CONDUCTOR_PARAMETERS_FILENAME = 'parameters.json'
  CONDUCTOR_PATTERN_TEMP_DIR = 'tmp'
  CONDUCTOR_PATTERN_RESOURCES_DIR = 'resources'
  CONDUCTOR_PATTERN_CHEFREPO_DIR = 'chef-repo'
  CONDUCTOR_PATTERN_ROLES_DIR = 'roles'
  CONDUCTOR_SERF_PAYLOAD_FILENAME = 'payload.json'

  CHEFSOLO_LOG_DIR = 'logs'
  CHEFSOLO_LOG_FILENAME = 'chef-solo.log'
  CHEFSOLO_LOG_LEVEL = 'info'
  CHEFSOLO_FILECACHE_DIR = 'cache'
  CHEFSOLO_CONFIG_FILENAME = 'solo.rb'
  CHEFSOLO_NODE_FILENAME = 'node.json'

  def initialize(script_role, script_event)
    @roles = ENV['SERF_TAG_ROLE'].split(',')
    @script_role = script_role
    @script_event = script_event
    module_dir = File.realpath(File.dirname(__FILE__)).split(File::SEPARATOR)
    pattern_name_index = module_dir.index('patterns') + 1
    @pattern_name = module_dir[pattern_name_index]
  end

  def execute
    return unless target?
    pattern_dir = File.join(CONDUCTOR_PATTERNS_ROOT_DIR, @pattern_name)
    chefsolo_log_dir, chefsolo_filecache_dir = create_chefsolo_directories(pattern_dir)
    chefrepo_dir, chefsolo_config_file = create_chefsolo_config_file(pattern_dir, chefsolo_log_dir, chefsolo_filecache_dir)
    chefsolo_node_file = create_chefsolo_node_file(pattern_dir)
    system("cd #{chefrepo_dir}; berks vendor ./cookbooks")
    system("chef-solo -c #{chefsolo_config_file} -j #{chefsolo_node_file}")
  end

  private

  def update_and_read_parameters_file(pattern_dir)
    payload_file = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CONDUCTOR_SERF_PAYLOAD_FILENAME)
    parameters_file = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CONDUCTOR_PARAMETERS_FILENAME)
    payload = {}
    parameters = {}
    payload = JSON.parse(File.read(payload_file)) if File.exist?(payload_file)
    parameters = JSON.parse(File.read(parameters_file)) if File.exist?(parameters_file)
    parameters.merge!(payload)
    parameters.merge!(

        serf: {
          agent: {
            tags: {
              role: ENV['SERF_TAG_ROLE']
            }
          }
        }

    )
    File.write(parameters_file, parameters.to_json)
    parameters
  end

  def create_chefsolo_config_file(pattern_dir, chefsolo_log_dir, chefsolo_filecache_dir)
    chefsolo_config_file = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_CONFIG_FILENAME)
    chefrepo_dir = File.join(pattern_dir, CONDUCTOR_PATTERN_RESOURCES_DIR, CONDUCTOR_PATTERN_CHEFREPO_DIR)
    roles_dir = File.join(chefrepo_dir, 'roles')
    chefsolo_log_file = File.join(chefsolo_log_dir, "#{@script_role}_#{CHEFSOLO_LOG_FILENAME}")
    cookbooks_dir = File.join(chefrepo_dir, 'cookbooks')
    site_cookbooks_dir = File.join(chefrepo_dir, 'site-cookbooks')

    File.open(chefsolo_config_file, 'w') do |file|
      file.write("role_path '#{roles_dir}'\n")
      file.write("log_level :#{CHEFSOLO_LOG_LEVEL}\n")
      file.write("log_location '#{chefsolo_log_file}'\n")
      file.write("file_cache_path '#{chefsolo_filecache_dir}'\n")
      file.write("cookbook_path ['#{cookbooks_dir}', '#{site_cookbooks_dir}']\n")
    end
    [chefrepo_dir, chefsolo_config_file]
  end

  def create_chefsolo_run_list
    ["role[#{@script_role}_#{@script_event}]"]
  end

  def create_chefsolo_node_file(pattern_dir)
    chefsolo_node_file = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_NODE_FILENAME)
    attributes = update_and_read_parameters_file(pattern_dir)
    attributes[:run_list] = create_chefsolo_run_list
    File.write(chefsolo_node_file, attributes.to_json)
    chefsolo_node_file
  end

  def create_chefsolo_directories(pattern_dir)
    chefsolo_log_dir = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_LOG_DIR)
    chefsolo_filecache_dir = File.join(pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_FILECACHE_DIR)
    FileUtils.mkdir_p(chefsolo_log_dir)
    FileUtils.mkdir_p(chefsolo_filecache_dir)
    [chefsolo_log_dir, chefsolo_filecache_dir]
  end

  def target?
    @roles.include? @script_role
  end
end
