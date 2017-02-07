if defined?('ChefSpec')
  def install_python_runtime(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:python_runtime, :install, resource)
  end
end
