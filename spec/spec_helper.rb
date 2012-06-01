$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'candy'
require 'rspec'
require 'rspec/autorun'
require 'mocha'


# Support methods
Candy.db = 'candy_test'
Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  
  config.before(:all) do
  end
    
  config.after(:all) do
    c = Mongo::Connection.new
    c.drop_database('candy_test')
  end
end
