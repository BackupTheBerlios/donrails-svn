# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def pub_date(time)
    time.strftime "%a, %e %b %Y %H:%M:%S %Z"
  end

  def remove_html_gl(text, format)
    case format
    when "hnf"
      hnf_remove_html_gl(text)
    end
  end

  def hnf_remove_html_gl(text)
    text.chomp!
    text.gsub!(/<.*>/,'')
    text.gsub!(/\s+/, ' ')
  end
  private :hnf_remove_html_gl

  def don_link(text, format)
    case format
    when "hnf"
      hnf_don_link(text)
    end
  end

  ## HNF format to HTML. mainly LINK.
  def hnf_don_link(text)
    if text.nil? then return end
    stext = Array.new
    @pre_tag = false
    text.split("\n").each do |line|

      line = hnf_don_line_pre(line)
      unless @pre_tag
        line = hnf_don_line_ok(line)
        line = hnf_don_line_user_var(line)
        line = hnf_don_line_sub(line)
        line = hnf_don_line_link(line)
        line = hnf_don_line_img(line)
        line = hnf_don_line_7e(line)
        line = hnf_don_line_ul(line)
      end
      stext.push(line)
    end
    return stext.join("\n")
  end
  private :hnf_don_link

  def  hnf_don_line_ok(text)
    if text =~ /^OK/
      text = ""
    end
    return text
  end
  private :hnf_don_line_ok

  # http://www.h14m.org/docs/user_var-j.html
  def hnf_don_line_user_var(text)
    if text =~ /^(TENKI|WEATHER|BASHO|LOCATION|TAIJU|WEIGHT|TAION|TEMPERATURE|SUIMIN|SLEEP|BGM|HOSU|STEP|HON|BOOK|KITAKU|HOMECOMING|WALK|RUN)\s+(.+)/
      text = ""
    end
    return text
  end
  private :hnf_don_line_user_var

  def hnf_don_line_sub(text)
    if text =~ /^SUB\s+(.+)/
      text = "<p><b>#{$1}</b>:"
    end
    if text =~ /^LSUB\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i
      text = "<p><b><a href=\"#{$1}://#{$2}\">#{$3}</a></b>"
    end
    return text
  end
  private :hnf_don_line_sub

  def hnf_don_line_pre(text)
    if text =~ /^PRE/
      text = "<PRE>"
      @pre_tag = true
    elsif text =~ /^\/PRE/
      text = "</PRE>"
      @pre_tag = false
    end
    return text
  end

  def hnf_don_line_ul(text)
    if text =~ /^(\/)?(UL|P|OL|DL)/
      text = "<#{$1}#{$2}>"
    end
    if text =~ /^(\/)?(CITE)/
      unless $1
        text = "<p><#{$2}>"
      else
        text = "<#{$1}#{$2}></p>"
      end
    end
    if text =~ /^LI\s+(.+)/   # DT? DD?
      text = "<li>#{$1}"
    elsif text =~ /^LI/   # DT? DD?
      text = "<li>"
    end
    return text
  end
  private :hnf_don_line_ul


  def hnf_don_line_link(line)
    if line =~ /^LINK\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i
      line = "<a href=\"#{$1}://#{$2}\">#{$3}</a>"
    end
    return line
  end
  private :hnf_don_line_link

  def hnf_don_line_img(line)
    if line =~ /^L?IMG\s+(l|r|n)\s+(\S+)\.(jpg|jpeg|gif|png)/i
      line = $2
      if $1 == "l"
        line = "<img align=\"left\" src=\"#{$2}.#{$3}\">"
      elsif $1 == "r"
        line = "<img align=\"right\" src=\"#{$2}.#{$3}\">"
      else
        line = "<img src=\"#{$2}.#{$3}\">"
      end
    end
    return line
  end
  private :hnf_don_line_img

  def hnf_don_line_7e(line)

      if line =~ /^~/
        line = "<br>"
      end
    return line
  end
  private :hnf_don_line_7e

  def don_lnew(text, format)
    case format
    when "hnf"
      hnf_don_lnew(text)
    end
  end

  def hnf_don_lnew(text)
    if text =~ /^(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i
      text = "<a href=\"#{$1}://#{$2}\">#{$3}</a>"
    end
    return text
  end
  private :hnf_don_lnew

end
