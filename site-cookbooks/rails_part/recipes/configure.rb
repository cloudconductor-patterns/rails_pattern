unless node['postfix']['sasl'].nil? || node['postfix']['sasl'].empty?
  include_recipe 'postfix::sasl_auth'
end
