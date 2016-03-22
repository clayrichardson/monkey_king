$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'monkey_king'

def load_file(filename)
  File.read(File.expand_path(File.join(__FILE__, '../fixture/', filename)))
end

def fixture_file_path(filename)
  File.expand_path(File.join(__FILE__, '../fixture/', filename))
end

def load_fixtures(fixture_name)
   before = load_file("#{fixture_name}_before.yml")
   after = load_file("#{fixture_name}_after.yml")
   return before, after
end
