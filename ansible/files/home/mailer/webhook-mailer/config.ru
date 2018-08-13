# -*- mode: ruby -*-

require "yaml"

require "pathname"

base_dir = Pathname(__FILE__).dirname

require "webhook-mailer"

require "racknga/middleware/exception_notifier"

use Rack::CommonLogger
use Rack::Runtime
use Rack::ContentLength

config_file = base_dir + "config.yaml"
options = YAML.load_file(config_file.to_s)
notifier_options = options.dup
if options["error_to"]
  notifier_options["to"] = options["error_to"]
end
notifier_options.merge!(options["exception_notifier"] || {})
notifiers = [Racknga::ExceptionMailNotifier.new(notifier_options)]
use Racknga::Middleware::ExceptionNotifier, :notifiers => notifiers

run WebhookMailer::App.new(options)
