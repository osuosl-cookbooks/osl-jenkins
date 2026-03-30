# Work around ffi-yajl 2.7.7 (shipped with Cinc 18) incorrectly depending on the 'yajl' gem (a logger, not a JSON
# parser). Both sawyer and multi_json detect the Yajl constant and try to use it as a JSON adapter, but Yajl.dump and
# Yajl::ParseError don't exist in the logger gem. Patch sawyer to rescue NameError and force multi_json to use
# json_gem.
require 'sawyer'
Sawyer::Serializer.define_singleton_method(:yajl) do
  require 'yajl'
  new(Yajl)
rescue LoadError, NameError
end

require 'multi_json'
MultiJson.use :json_gem
