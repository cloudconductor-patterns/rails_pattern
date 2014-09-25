# -*- coding: utf-8 -*-

require 'fileutils'
require 'json'
require 'logger'
require 'rest-client'
require 'base64'
require 'active_support'

# rubocop: disable ClassLength
class PatternExecutor
  PATTERN_NAME = 'rails_pattern'
  PATTERN_DIR = "/opt/cloudconductor/patterns/#{PATTERN_NAME}"
  ROLES_DIR="#{PATTERN_DIR}/roles"
  CONSUL_KVS_PARAMETERS_URL = 'http://127.0.0.1:8500/v1/kv/cloudconductor/parameters'
  LOG_FILE = "#{PATTERN_DIR}/tmp/logs/pattern_executor.log"

  def initialize(event)
    @logger = Logger.new(LOG_FILE)
    @event = event
  end

  def execute_chef(node_role)
    roles = node_role.split(',')
    roles << 'all'
    roles.each do |role|
      role_file = "#{ROLES_DIR}/#{role}_#{@event}.json"
      if File.exists?(role_file)
        @logger.info("execute chef with [#{role_file}].")
        begin
          create_chefsolo_directories
          create_chefsolo_config_file(role)
          create_chefsolo_node_file(role)
          run_chefsolo
          @logger.info('finished successfully.')
        rescue => exception
          @logger.error("finished abnormally. #{exception.message}")
          raise
        end
      else
        @logger.info("role file [#{role_file}] does not exists.")
      end
    end
  end

  private

  def read_parameters
    parameters = {}
    begin
      response = RestClient.get(CONSUL_KVS_PARAMETERS_URL)
      response_hash = JSON.parse(response, symbolize_names: true).first
      parameters_json = Base64.decode64(response_hash[:Value])
      parameters = JSON.parse(parameters_json, symbolize_names: true)
      @logger.info("read parameters successfully.: #{parameters}")
    rescue => exception
      @logger.warn("failed to get the parameters from Consul KVS. #{exception.message}")
    end
    parameters
  end

  def create_chefsolo_directories
    chefsolo_log_dir = File.join(PATTERN_DIR, 'tmp/logs')
    chefsolo_filecache_dir = File.join(PATTERN_DIR, 'tmp/cache')
    FileUtils.mkdir_p(chefsolo_log_dir) unless Dir.exist?(chefsolo_log_dir)
    FileUtils.mkdir_p(chefsolo_filecache_dir) unless Dir.exist?(chefsolo_filecache_dir)
  end

  def create_chefsolo_config_file(role)
    chefsolo_log_dir = File.join(PATTERN_DIR, 'tmp/logs')
    chefsolo_filecache_dir = File.join(PATTERN_DIR, 'tmp/cache')
    chefsolo_config_file = File.join(PATTERN_DIR, 'tmp/solo.rb')
    roles_dir = File.join(PATTERN_DIR, 'roles')
    chefsolo_log_file = File.join(chefsolo_log_dir, "#{role}_chef-solo.log")
    cookbooks_dir = File.join(PATTERN_DIR, 'cookbooks')
    site_cookbooks_dir = File.join(PATTERN_DIR, 'site-cookbooks')
    File.open(chefsolo_config_file, 'w') do |file|
      file.write("role_path '#{roles_dir}'\n")
      file.write("log_level :info\n")
      file.write("log_location '#{chefsolo_log_file}'\n")
      file.write("file_cache_path '#{chefsolo_filecache_dir}'\n")
      file.write("cookbook_path ['#{cookbooks_dir}', '#{site_cookbooks_dir}']\n")
    end
  end

  def create_chefsolo_node_file(role)
    chefsolo_node_file = File.join(PATTERN_DIR, 'tmp/node.js')
    parameters = read_parameters
    attributes = parameters[:cloudconductor][:patterns][PATTERN_NAME.to_sym][:user_attributes]
    attributes[:run_list] = ["role[#{role}_#{@event}]"]
    File.write(chefsolo_node_file, attributes.to_json)
    @logger.info('created chefsolo_node_file successfully.')
    chefsolo_node_file
  end

  def run_chefsolo
    chefsolo_config_file = File.join(PATTERN_DIR, 'tmp/solo.rb')
    chefsolo_node_file = File.join(PATTERN_DIR, 'tmp/node.js')
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
# rubocop: enable ClassLength

node_role = ARGV[0]
event = ARGV[1]
puts "node_role = #{node_role}"
puts "event = #{event}"
PatternExecutor.new(event).execute_chef(node_role)
