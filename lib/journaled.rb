require "aws-sdk-kinesis"
require "active_job"
require "json-schema"
require "request_store"

require "journaled/engine"

module Journaled
  SUPPORTED_QUEUE_ADAPTERS = %w(delayed delayed_job good_job que).freeze

  mattr_accessor :default_app_name
  mattr_accessor(:job_priority) { 20 }
  mattr_accessor(:http_idle_timeout) { 5 }
  mattr_accessor(:http_open_timeout) { 2 }
  mattr_accessor(:http_read_timeout) { 60 }
  mattr_accessor(:job_base_class_name) { 'ActiveJob::Base' }

  def development_or_test?
    %w(development test).include?(Rails.env)
  end

  def enabled?
    !['0', 'false', false, 'f', ''].include?(ENV.fetch('JOURNALED_ENABLED', !development_or_test?))
  end

  def schema_providers
    @schema_providers ||= [Journaled::Engine, Rails]
  end

  def commit_hash
    ENV.fetch('GIT_COMMIT')
  end

  def actor_uri
    Journaled::ActorUriProvider.instance.actor_uri
  end

  def detect_queue_adapter!
    adapter = job_base_class_name.constantize.queue_adapter.class.name.split('::').last.underscore.gsub("_adapter", "")
    unless SUPPORTED_QUEUE_ADAPTERS.include?(adapter)
      raise <<~MSG
        Journaled has detected an unsupported ActiveJob queue adapter: `:#{adapter}`

        Journaled jobs must be enqueued transactionally to your primary database.

        Please install the appropriate gems and set `queue_adapter` to one of the following:
        #{SUPPORTED_QUEUE_ADAPTERS.map { |a| "- `:#{a}`" }.join("\n")}

        Read more at https://github.com/Betterment/journaled
      MSG
    end
  end

  module_function :development_or_test?, :enabled?, :schema_providers, :commit_hash, :actor_uri, :detect_queue_adapter!
end
