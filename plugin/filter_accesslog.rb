module Fluent
  class AccesslogFilter < Filter
    Plugin.register_filter('accesslog', self)

    config_param :remove_fields, :string, :default => ''

    def configure(conf)
      super
      @remove_fields_list = @remove_fields.split(',')
    end


    def filter(tag, time, record)
      # elim no_data
      begin
        record.reject!{ |k,v| v == '-' }
      rescue => e
        log.warn "failed to eliminate hyphen", :error_class => e.class, :error => e.message
        log.warn_backtrace
      end

      # remove keys
      begin
        @remove_fields_list.each do |field|
          record.delete(field)
        end
      rescue => e
        log.warn "failed to delete field", :error_class => e.class, :error => e.message
        log.warn_backtrace
      end
      record
    end
  end
end
