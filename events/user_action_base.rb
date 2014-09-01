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
require 'logger'
require 'rest-client'
require 'base64'

class UserActionBase
  CONDUCTOR_ROOT_DIR = '/opt/cloudconductor'
  CONDUCTOR_PATTERNS_ROOT_DIR = File.join(CONDUCTOR_ROOT_DIR, 'patterns')
  CONDUCTOR_PATTERN_TEMP_DIR = 'tmp'
  CONDUCTOR_PATTERN_RESOURCES_DIR = 'resources'
  CONDUCTOR_PATTERN_CHEFREPO_DIR = 'chef-repo'
  CONDUCTOR_PATTERN_ROLES_DIR = 'roles'
  CONDUCTOR_SERF_PAYLOAD_FILENAME = 'payload.json'
  CONDUCTOR_CONSUL_KVS_URL = 'http://127.0.0.1:8500/v1/kv'
  CONDUCTOR_CONSUL_KVS_PARAMETERS_URL = "#{CONDUCTOR_CONSUL_KVS_URL}/cloudconductor/parameters"
  CONDUCTOR_CONSUL_KVS_STORED_PARAMETERS_URL = "#{CONDUCTOR_CONSUL_KVS_URL}/cloudconductor/stored_parameters"
  CONDUCTOR_LOG_FILE = '/tmp/user_action_base.log'

  CHEFSOLO_LOG_DIR = 'logs'
  CHEFSOLO_LOG_FILENAME = 'chef-solo.log'
  CHEFSOLO_LOG_LEVEL = 'info'
  CHEFSOLO_FILECACHE_DIR = 'cache'
  CHEFSOLO_CONFIG_FILENAME = 'solo.rb'
  CHEFSOLO_NODE_FILENAME = 'node.json'

  def initialize(role, event, additional_parameters = {})
    @logger = Logger.new(CONDUCTOR_LOG_FILE)
    @role = role
    @event = event
    @logger.debug("role = #{@role}")
    @logger.debug("event = #{@event}")
    @logger.debug("additional_parameters = #{additional_parameters}")
    script_file = File.expand_path(__FILE__)
    pattern_name = script_file.slice(%r{#{CONDUCTOR_PATTERNS_ROOT_DIR}/(?<pattern_name>[^/]*)}, 'pattern_name')
    @pattern_dir = File.join(CONDUCTOR_PATTERNS_ROOT_DIR, pattern_name)
    @logger.debug("pattern_dir = #{@pattern_dir}")
    parameters = read_parameters(CONDUCTOR_CONSUL_KVS_PARAMETERS_URL)
    user_parameters = parameters[:parameters].nil? ? {} : parameters[:parameters]
    application_url = parameters[:url].nil? ? '' : parameters[:url]
    application_revision = parameters[:revision].nil? ? '' : parameters[:revision]
    application_parameters = {
      cloudconductor: {
        application_url: application_url,
        application_revision: application_revision
      }
    }
    user_parameters.merge!(application_parameters)
    user_parameters.merge!(additional_parameters)
    update_parameters(CONDUCTOR_CONSUL_KVS_STORED_PARAMETERS_URL, user_parameters)
  end

  def execute(forced = false)
    @logger.debug("forced = #{forced}")
    node_roles = ENV['SERF_TAG_ROLE'].split(',')
    @logger.debug("node_roles = #{node_roles}")
    return unless forced || node_roles.include?(@role)
    begin
      create_chefsolo_directories
      create_chefsolo_config_file
      create_chefsolo_node_file
      run_chefsolo
      @logger.info('finished successfully.')
    rescue => exception
      @logger.error("finished abnormally. #{exception.message}")
      fail
    end
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

  def read_parameters(url)
    parameters = {}
    begin
      response = RestClient.get(url)
      @logger.debug("response = #{response}")
      response_hash = JSON.parse(response, symbolize_names: true).first
      @logger.debug("response_hash = #{response_hash}")
      parameters_json = Base64.decode64(response_hash[:Value])
      @logger.debug("parameters_json = #{parameters_json}")
      parameters = JSON.parse(parameters_json, symbolize_names: true)
    rescue => exception
      @logger.warn("failed to get the parameters[#{url}] from Consul KVS. #{exception.message}")
    end
    @logger.debug("read parameters = #{parameters}")
    parameters
  end

  def update_parameters(url, parameters)
    @logger.debug("parameters = #{parameters}")
    stored_parameters = read_parameters(url)
    @logger.debug("stored_parameters = #{stored_parameters}")
    stored_parameters.merge!(parameters)
    @logger.debug("mergd_parameters = #{stored_parameters}")
    begin
      RestClient.put(url, stored_parameters.to_json)
    rescue => exception
      @logger.error("failed to put the parameters[#{url}] to Consul KVS. #{exception.message}")
      fail
    end
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
    attributes = read_parameters(CONDUCTOR_CONSUL_KVS_STORED_PARAMETERS_URL)
    attributes[:run_list] = ["role[#{@role}_#{@event}]"]
    File.write(chefsolo_node_file, attributes.to_json)
    chefsolo_node_file
  end

  def run_chefsolo
    chefrepo_dir = File.join(@pattern_dir, CONDUCTOR_PATTERN_RESOURCES_DIR, CONDUCTOR_PATTERN_CHEFREPO_DIR)
    chefsolo_config_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_CONFIG_FILENAME)
    chefsolo_node_file = File.join(@pattern_dir, CONDUCTOR_PATTERN_TEMP_DIR, CHEFSOLO_NODE_FILENAME)
    berks_result = system("cd #{chefrepo_dir}; berks vendor ./cookbooks")
    @logger.debug("berks result = #{berks_result}")
    chef_solo_result = system("chef-solo -c #{chefsolo_config_file} -j #{chefsolo_node_file}")
    @logger.debug("chef-solo result = #{chef_solo_result}")
    raise RuntimeError, 'chef-solo finished abnormally.' unless chef_solo_result;
  end
end
