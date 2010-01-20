# See: http://github.com/mynyml/watchr/

require 'redgreen'
require 'autowatchr'

Autowatchr.new(self) do |config|
  config.test_dir = 'spec'
  config.test_re = "^#{config.test_dir}/(.*)_spec\.rb$"
  config.test_file = '%s_spec.rb'
end
# watch ( 'spec/.*_spec\.rb' ) { |spec| system("ruby #{spec[0]}")}
# watch ( 'lib/(.*).rb' ) { |lib| system("ruby spec/#{spec[1]}_spec.rb")}