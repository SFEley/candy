# Make me one with everything...
Dir[File.join(File.dirname(__FILE__), 'candy', '*.rb')].each {|f| require f}

require 'candy/exceptions'
require 'candy/crunch'
require 'candy/wrapper'
require 'candy/piece'
require 'candy/collection'

