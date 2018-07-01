require 'hyperloop/transport/version'
if RUBY_ENGINE == 'opal'
  require 'hyperloop/transport'
  require 'hyperloop/transport/pusher/event_support'
  require 'hyperloop/transport/pusher/channel'
else
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end