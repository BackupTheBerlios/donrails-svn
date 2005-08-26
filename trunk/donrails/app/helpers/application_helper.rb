# The methods added to this helper will be available to all templates in the application.

require 'hnf_helper'
require 'time'

module ApplicationHelper
  include HNF

  def pub_date(time)
    time.iso8601
  end

  def remove_html_gl(text, format)
    case format
    when "hnf"
      hnf_remove_html_gl(text)
    when "plain"
      plain_remove_html_gl(text)
    end
  end

  def don_lnew(text, format)
    case format
    when "hnf"
      hnf_don_lnew(text)
    else
      plain_don_lnew(text)
    end
  end

  def don_link(text, format)
    case format
    when "hnf"
      hnf_don_link(text)
    when "plain"
      plain_don_link(text)
    end
  end

  
  def plain_remove_html_gl(text)
    text.chomp!
    text.gsub!(/<.*>/,'')
    text.gsub!(/\s+/, ' ')
  end
  private :plain_remove_html_gl

  def plain_don_link(text)
    if text.nil? then return end
    stext = Array.new
    @pre_tag = false
    text.split("\n").each do |line|
      line = plain_don_line_link(line)
      line = plain_don_line_2kaigyo(line)
      stext.push(line)
    end
    return stext.join("\n")
  end
  private :plain_don_link

  def plain_don_line_link(line)
    if line =~ /^LINK\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i
      line = "<a href=\"#{$1}://#{$2}\">#{$3}</a>"
    end
    return line
  end
  private :plain_don_line_link

  def plain_don_line_2kaigyo(line)
    if line == ""
      line = "<br>"
    end
    return line
  end
  private :plain_don_line_2kaigyo

  def plain_don_lnew(text)
    return text
  end
  private :plain_don_lnew


end
