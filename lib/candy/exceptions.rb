# encoding: utf-8
module Candy
  # Every other exception type falls under CandyError for easy catching.
  class CandyError < StandardError; end
    
  class ConnectionError < CandyError; end
  
  class TypeError < CandyError; end
end