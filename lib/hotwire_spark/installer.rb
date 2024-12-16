class HotwireSpark::Installer
  attr_reader :file_watcher

  def initialize(application)
    @application = application
  end

  def install
    configure_middleware
    monitor_paths
  end

  def configure_middleware
    ::ActionCable::Server::Base.prepend(HotwireSpark::ActionCable::PersistentCableServer)

    middleware.insert_before ActionDispatch::Executor, HotwireSpark::ActionCable::PersistentCableMiddleware
    middleware.use HotwireSpark::Middleware
  end

  private
    attr_reader :application
    delegate :middleware, to: :application

    def monitor_paths
      register_monitored_paths
      file_watcher.start
    end

    def register_monitored_paths
      monitor :css_paths, action: :reload_css
      monitor :html_paths, action: :reload_html
      monitor :stimulus_paths, action: :reload_stimulus
    end

    def monitor(paths_name, action:)
      file_watcher.monitor HotwireSpark.public_send(paths_name) do |file_path|
        broadcast_reload_action(action, file_path)
      end
    end

    def broadcast_reload_action(action, file_path)
      ActionCable.server.broadcast "hotwire_spark", reload_message_for(action, file_path)
    end

    def reload_message_for(action, file_path)
      { action: action, path: file_path }
    end

    def file_watcher
      @file_watches ||= HotwireSpark::FileWatcher.new
    end
end