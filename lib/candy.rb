# encoding: utf-8

# Make me one with everything...
Dir[File.join(File.dirname(__FILE__), 'candy', '*.rb')].each {|f| require f}

# Special keys for Candy metadata in the Mongo store. We try to keep these to a minimum, 
# and we're using moderately obscure Unicode symbols to reduce the odds of collisions.
# If by some strange happenstance you might have single-character keys in your Mongo 
# collections that use the 'CIRCLED LATIN SMALL LETTER' Unicode set, you may need to
# change these constants.  Just be consistent about it if you want to use embedded
# documents in Candy.
CLASS_KEY = 'ⓒ'.to_sym
EMBED_KEY = 'ⓔ'.to_sym