module Jobrnr
  PostDefinitionMessage = Struct.new(:definition, :options)
  PreInstanceMessage = Struct.new(:instance, :options)
  PostInstanceMessage = PreInstanceMessage
  PostIntervalMessage = Struct.new(:completed_instances, :started_instances, :stats, :options)
  PostApplicationMessage = Struct.new(:reason, :completed_instances, :stats, :options)
end
