require 'ipaddr'

module Fluent
  class XForwardedForFilter < Filter
    Plugin.register_filter('x_forwarded_for', self)

    DEFAULT_PROXY_LIST = "127.0.0.1/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

    config_param :forwarded_for_key, :string, :default => 'x_forwarded_for'
    config_param :out_key, :string, :default => 'client_ip'
    config_param :remote_addr_key, :string, :default => 'remote_addr'
    config_param :proxy_ip_list, :string, :default => DEFAULT_PROXY_LIST

    def configure(conf)
      super
      @proxy_list = @proxy_ip_list.split(',').map {|proxy_ip| IPAddr.new(proxy_ip.strip)}
    end

    def filter(tag, time, record)
      if record[@forwarded_for_key] == '-'
        record.delete(@forwarded_for_key)
      end
      ip_list = [record[@remote_addr_key]]

      if record[@forwarded_for_key]
        ip_list.concat(record[@forwarded_for_key].split(','))
      end
      ip_list.reverse!

      ip_list.each do |ip_text|
        begin
          ip_addr = IPAddr.new(ip_text.strip)
        rescue
          next
        end

        catch(:is_proxy_ip) do
          @proxy_list.each do |proxy|
            throw :is_proxy_ip if proxy.include?(ip_addr)
          end
          record[@out_key] = ip_text.strip
          return record
        end

      end
      record[@out_key] = '0.0.0.0'
      record
    end
  end
end
