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

  def initialize(role, event, additional_parameters = {})
    @role = role
    @event = event
    script_file = File.expand_path(__FILE__)
    pattern_name = script_file.slice(%r{#{CONDUCTOR_PATTERNS_ROOT_DIR}/(?<pattern_name>[^/]*)}, 'pattern_name')
    @pattern_dir = File.join(CONDUCTOR_PATTERNS_ROOT_DIR, pattern_name)
    parameters = read_payload_file
    parameters.merge!(additional_parameters)
    update_parameters_file(parameters)
  end

  def execute(forced = false)
    node_roles = ENV['SERF_TAG_ROLE'].split(',')
    return unless forced || node_roles.include?(@role)
    create_chefsolo_directories
    create_chefsolo_config_file
    create_chefsolo_node_file
    run_chefsolo
  end

  def self.select_hosts(role)
    hosts = []
    serf_member_list = `serf members -tag 'role=[^,]*(,|)#{role}(,.*|)'`.strip
    unless serf_member_list.empty?
      serf_member_list.each_line do |serf_member|
        host_and_port = serf_member.split(' ')[1]
        host = host_and_port.split(':').first
        hosts << host
      end
    end
    hosts
  end

  private

  def read_payload_file
    payload = {}
    payload_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CONDUCTOR_SERF_PAYLOAD_FILENAME)
    payload = JSON.parse(File.read(payload_file), symbolize_names: true) if File.exist?(payload_file)
    payload
  end

  def read_parameters_file
    parameters = {}
    parameters_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CONDUCTOR_PARAMETERS_FILENAME)
    parameters = JSON.parse(File.read(parameters_file), symbolize_names: true) if File.exist?(parameters_file)
    parameters
  end

  def update_parameters_file(new_parameters)
    parameters_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CONDUCTOR_PARAMETERS_FILENAME)
    parameters = read_parameters_file
    parameters.merge!(new_parameters)
    File.write(parameters_file, parameters.to_json)
  end

  def create_chefsolo_directories
    chefsolo_log_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_LOG_DIR)
    chefsolo_filecache_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_FILECACHE_DIR)
    FileUtils.mkdir_p(chefsolo_log_dir) unless Dir.exist?(chefsolo_log_dir)
    FileUtils.mkdir_p(chefsolo_filecache_dir) unless Dir.exist?(chefsolo_filecache_dir)
  end

  def create_chefsolo_config_file
    chefsolo_log_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_LOG_DIR)
    chefsolo_filecache_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_FILECACHE_DIR)
    chefsolo_config_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_CONFIG_FILENAME)
    chefrepo_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_RESOURCES_DIR, CONDUCTOR_PATTERN_CHEFREPO_DIR)
    roles_dir = File.join(chefrepo_dir, 'roles')
    chefsolo_log_file = File.join(chefsolo_log_dir, "#{@role}_#{CHEFSOLO_LOG_FILENAME}")
    cookbooks_dir = File.join(chefrepo_dir, 'cookbooks')
    site_cookbooks_dir = File.join(chefrepo_dir, 'site-cookbooks')

    File.open(chefsolo_config_file, 'w') do |file|
      file.write("role_path '#{roles_dir}'\n")
      file.write("log_level :#{CHEFSOLO_LOG_LEVEL}\n")
      file.write("log_location '#{chefsolo_log_file}'\n")
      file.write("file_cache_path '#{chefsolo_filecache_dir}'\n")
      file.write("cookbook_path ['#{cookbooks_dir}', '#{site_cookbooks_dir}']\n")
    end
  end

  def create_chefsolo_node_file
    chefsolo_node_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_NODE_FILENAME)
    attributes = read_parameters_file
    attributes[:run_list] = ["role[#{@role}_#{@event}]"]
    File.write(chefsolo_node_file, attributes.to_json)
    chefsolo_node_file
  end

  def run_chefsolo
    chefrepo_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_RESOURCES_DIR, CONDUCTOR_PATTERN_CHEFREPO_DIR)
    chefsolo_config_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_CONFIG_FILENAME)
    chefsolo_node_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_NODE_FILENAME)
    system("cd #{chefrepo_dir}; berks vendor ./cookbooks")
    system("chef-solo -c #{chefsolo_config_file} -j #{chefsolo_node_file}")
  end
end
