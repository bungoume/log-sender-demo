module Fluent
  class NginxlogFilter < Filter
    Plugin.register_filter('nginxlog', self)

    def filter(tag, time, record)
      record['taken_time_ms'] = record['taken_time'].to_f * 1000
      record.delete('taken_time')

      record['timestamp_ms'] = (record['timestamp'].to_f * 1000).to_i
      record.delete('timestamp')

      begin
        if record['upstream_taken_time'] == '-'
          record.delete('upstream_taken_time')
        else
          record['upstream_taken_time_ms'] = record['upstream_taken_time'].to_f * 1000
          record.delete('upstream_taken_time')
        end
      rescue => e
        record.delete('upstream_taken_time')
        log.warn "failed to change upstream_taken_time", :error_class => e.class, :error => e.message
        log.warn_backtrace
      end
      record
    end
  end
end
