
$: << File.join(File.dirname(__FILE__), '../lib')
require 'grandcloud'
require 'rspec'

RSpec.configure do |config|
  config.include RSpec::Matchers

  config.mock_with :rspec
end

module GrandCloud

  GrandCloud::Base.secret_access_key = 'YmU0Mzk5NDYtZGZlMC00ZmNiLWI0Y2YtNzA4NGQxYzk4MGQ1'
  GrandCloud::Base.snda_access_key_id = 'BH297OBMKFV0T2LO9MC189P2J'

end
