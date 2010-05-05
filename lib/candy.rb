# encoding: utf-8

require 'candy/crunch'
require 'candy/exceptions'

module Candy
  # Let's be minimalist here.  Some implementations may not need Collections, or Arrays, etc.
  # Anything not in the autoload list below is unlikely to be accessed directly by an end user.
  autoload :CandyHash, 'candy/hash'
  autoload :CandyArray, 'candy/array'
  autoload :Wrapper, 'candy/wrapper'
  autoload :Piece, 'candy/piece'
  autoload :Collection, 'candy/collection'
  
  # Special keys for Candy metadata in the Mongo store. We try to keep these to a minimum, 
  # and we're using moderately obscure Unicode symbols to reduce the odds of collisions.
  # If by some strange happenstance you might have single-character keys in your Mongo 
  # collections that use the 'CIRCLED LATIN SMALL LETTER' Unicode set, you may need to
  # change these constants.  Just be consistent about it if you want to use embedded
  # documents in Candy.
  CLASS_KEY = 'ⓒ'.to_sym
  EMBED_KEY = 'ⓔ'.to_sym
end

