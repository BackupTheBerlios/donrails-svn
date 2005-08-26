# The methods added to this helper will be available to all templates in the application.

require 'delegator'
require 'time'

module ApplicationHelper

=begin rdoc

=== ApplicationHelper#don_supported_formats

=end

  def don_supported_formats
    return DonRails::DataFormatDelegator.formatlist
  end # def don_supported_formats

=begin rdoc

=== ApplicationHelper#don_to_title(text, fmt)

=end

  def don_to_title(text, fmt)
    s = DonRails::DataFormatDelegator.new(text, fmt)

    return s.title
  end # def don_to_title

=begin rdoc

=== ApplicationHelper#don_to_html(text, fmt)

=end

  def don_to_html(text, fmt)
    s = DonRails::DataFormatDelegator.new(text, fmt)

    return s.to_html
  end # def don_to_html

=begin rdoc

=== ApplicationHelper#don_chomp_tags(text, format)

=end

  def don_chomp_tags(text, format)
    s = DonRails::DataFormatDelegator.new(text, fmt)

    return s.chomp_tags
  end # def don_chomp_tags

  def pub_date(time)
    time.iso8601
  end

end
