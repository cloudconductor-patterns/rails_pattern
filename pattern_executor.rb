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

require 'json'
require 'active_support'
require '/opt/cloudconductor/lib/pattern/pattern_util'
require '/opt/cloudconductor/lib/consul/consul_util'

class PatternExecutor
  PATTERN_NAME = 'rails_pattern'
  PATTERN_DIR = File.join(Pattern::PatternUtil::PATTERNS_ROOT_DIR, PATTERN_NAME)
  ROLES_DIR = File.join(PATTERN_DIR, 'roles')
  SPEC_ROOT_DIR = File.join(PATTERN_DIR, 'serverspec')
  SPEC_DIR = File.join(SPEC_ROOT_DIR, 'spec')

  def initialize(event)
    @logger = Pattern::PatternUtil.get_pattern_logger(PATTERN_NAME, 'executor.log')
    @event = event
  end

  def execute(node_role)
    if @event == 'spec'
      execute_serverspec(node_role)
    else
      execute_chef(node_role)
    end
  end

  private

  def execute_chef(node_role)
    roles = node_role.split(',')
    roles << 'all'
    roles.each do |role|
      role_file = "#{ROLES_DIR}/#{role}_#{@event}.json"
      if File.exists?(role_file)
        @logger.info("execute chef with [#{role_file}].")
        begin
          create_chefsolo_config_file(role)
          create_chefsolo_node_file(role)
          run_chefsolo
          @logger.info('finished successfully.')
        rescue => exception
          @logger.error("finished abnormally. #{exception.message}")
          raise
        end
      else
        @logger.info("role file [#{role_file}] does not exist. skipped.")
      end
    end
  end

  def execute_serverspec(node_role)
    roles = node_role.split(',')
    roles.unshift('all')
    events = ['configure']
    events << 'deploy' if @action == 'deploy'
    
    roles.each do |role|
      events.each do |event|
        spec_file = "#{SPEC_DIR}/#{role}/#{role}_#{event}.json"
        if File.exists?(spec_file)
          @logger.info("execute serverspec with [#{spec_file}].")
          spec_result = system("cd #{SPEC_ROOT_DIR}; rake spec[#{role},#{event}]")
        else
          @logger.info("spec file [#{spec_file}] does not exist. skipped.")
        end
      end
    end
  end

  def create_chefsolo_config_file(role)
    chefsolo_config_file = File.join(PATTERN_DIR, 'solo.rb')
    chefsolo_log_file = File.join(Pattern::PatternUtil::LOG_DIR, "#{PATTERN_NAME}_#{role}_chef-solo.log")
    cookbooks_dir = File.join(PATTERN_DIR, 'cookbooks')
    site_cookbooks_dir = File.join(PATTERN_DIR, 'site-cookbooks')
    File.open(chefsolo_config_file, 'w') do |file|
      file.write("role_path '#{ROLES_DIR}'\n")
      file.write("log_level :info\n")
      file.write("log_location '#{chefsolo_log_file}'\n")
      file.write("file_cache_path '#{Pattern::PatternUtil::FILECACHE_DIR}'\n")
      file.write("cookbook_path ['#{cookbooks_dir}', '#{site_cookbooks_dir}']\n")
    end
  end

  def create_chefsolo_node_file(role)
    chefsolo_node_file = File.join(PATTERN_DIR, 'node.js')
    parameters = Consul::ConsulUtil.read_parameters
    attributes = parameters[:cloudconductor][:patterns][PATTERN_NAME.to_sym][:user_attributes]
    attributes[:run_list] = ["role[#{role}_#{@event}]"]
    File.write(chefsolo_node_file, attributes.to_json)
    @logger.info('created chefsolo_node_file successfully.')
    chefsolo_node_file
  end

  def run_chefsolo
    chefsolo_config_file = File.join(PATTERN_DIR, 'solo.rb')
    chefsolo_node_file = File.join(PATTERN_DIR, 'node.js')
    berks_result = system("cd #{PATTERN_DIR}; berks vendor ./cookbooks")
    if berks_result
      @logger.info('run berks successfully.')
    else
      @logger.warn('failed to run berks.')
    end
    chef_solo_result = system("chef-solo -c #{chefsolo_config_file} -j #{chefsolo_node_file}")
    if chef_solo_result
      @logger.info('run chef-solo successfully.')
    else
      fail
    end
  end
end

role = ARGV[0]
event = ARGV[1]
PatternExecutor.new(event).execute(role)
