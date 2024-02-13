resource_name :osl_jenkins_service
provides :osl_jenkins_service
unified_mode true

property :delay_start, [true, false],
          default: true,
          description: 'Delay service start until end of run'

action_class do
  def do_service_action(resource_action)
    if %i(start restart reload).include?(resource_action) && new_resource.delay_start
      declare_resource(:service, 'jenkins') do
        supports status: true, restart: true, reload: false

        delayed_action resource_action
      end
    else
      declare_resource(:service, 'jenkins') do
        supports status: true, restart: true, reload: false

        action resource_action
      end
    end
  end
end

%i(start stop restart reload enable disable).each do |action_type|
  send(:action, action_type) { do_service_action(action) }
end
