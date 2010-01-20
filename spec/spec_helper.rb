$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'candy'
require 'spec'
require 'spec/autorun'
require 'mocha'

Spec::Runner.configure do |config|
  config.mock_with :mocha
  
  config.before(:all) do
    $MONGO_DB = 'candy_test'
  end
    
  config.after(:all) do
    c = Mongo::Connection.new
    c.drop_database('candy_test')
  end
end
