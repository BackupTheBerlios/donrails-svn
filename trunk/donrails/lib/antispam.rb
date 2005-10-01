##
## antispam.rb 
##    written by ARAKI Yasuhiro <yasu@debian.or.jp>
##    License: GPL2
##
##    some code derived from "typo"
##

require_dependency 'blacklist'

class AntiSpam
  def initialize
    @IP_RBL = [ 'bsb.empty.us', 'list.dsbl.org' ]
    @HOST_RBL = [ 'sc.surbl.org', 'bsb.empty.us' ]
    @URL_LIMIT = 5
  end

  def is_spam?(name, string)
    return false if string.nil?
    return false if string == ""

    reason = catch(:hit) do
      if name == :url
        self.scan_uri(URI.parse(string).host)
      elsif name == :ipaddr
        self.scan_ipaddr(string)
      elsif name == :body
        self.scan_text(string)
      else
        return false # is not spam!
      end
    end

    if reason
      logger.info("[SP] Hit: #{reason}")
      return true
    end
  end

  def scan_ipaddr(ip_address)
    logger.info("[SP] Scanning IP #{ip_address}")

    Blacklist.find(:all, :conditions => ["format = ?", "ipaddr"]).each do |bp|
      logger.info("[SP] Scanning blacklist ipaddr #{bp}")
      throw :hit, "IPaddress #{bp.pattern} matched" if ip_address.match(/#{bp.pattern}/)
    end

    
    @IP_RBL.each do |rbl|
      begin
        if IPSocket.getaddress((ip_address.split('.').reverse + [rbl]).join('.')) == "127.0.0.2"
          throw :hit, "#{rbl} positively resolved #{ip_address}"
        end
      rescue SocketError
      end
    end
    return false
  end
  protected :scan_ipaddr

  def scan_uri(host)
    logger.info(host)
    host_parts = host.split('.').reverse
    domain = Array.new
    logger.info("[SP] Scanning domain #{domain.join('.')}")

    Blacklist.find(:all, :conditions => ["format = ?", "hostname"]).each do |bp|
      logger.info("[SP] Scanning blacklist host #{bp}")
      throw :hit, "Hostname #{bp.pattern} matched" if host.match(/#{bp.pattern}/)
    end
    
    @HOST_RBL.each do |rbl|
      begin
        if [
            IPSocket.getaddress([host, rbl].join('.')),
            IPSocket.getaddress((domain + [rbl]).join('.'))
          ].include?("127.0.0.2")
          throw :hit, "#{rbl} positively resolved #{domain.join('.')}"
        end
      rescue SocketError
      end
    end
    return false
  end
  protected :scan_uri

  def scan_text(string)
    logger.info("[SP] Scanning text #{string}")

    # Scan contained URLs
    uri_list = string.scan(/(http:\/\/[^\s"]+)/m).flatten

    # Check for URL count limit    
    if @URL_LIMIT > 0
      throw :hit, "Hard URL Limit hit: #{uri_list.size} > #{URL_LIMIT}" if uri_list.size > @URL_LIMIT
    end
    
    uri_list.collect { |uri| URI.parse(uri).host rescue nil }.uniq.compact.each do |host|
      scan_uri(host)
    end

    # add blacklist match here.
    Blacklist.find(:all, :conditions => ["format = ?", "regexp"]).each do |bp|
      logger.info("[SP] Scanning blacklist text #{bp}")
      throw :hit, "String #{bp.pattern} matched" if string.match(/#{Regexp.quote(bp.pattern)}/)
    end

    Blacklist.find(:all, :conditions => ["format = ?", "string"]).each do |bp|
      logger.info("[SP] Scanning blacklist text #{bp}")
      throw :hit, "Regex #{bp.pattern} matched" if string.match(/#{bp.pattern}/)
    end

    return false
  end
  protected :scan_text


  def logger
    @logger ||= RAILS_DEFAULT_LOGGER || Logger.new(STDOUT)
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      def validates_antispam(*attr_names)
        configuration = { :message => "blocked by AntiSpam" }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message]) if AntiSpam.new.is_spam?(attr_name, value)
        end
      end

    end
  end
end
