=begin

=HyperNikkiSystem file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as Ruby.

=end

require 'cgi'


module DonRails

=begin rdoc

== DonRails::HNF

=end

  module HNF
    include DonRails::PlainText

=begin rdoc

=== DonRails::HNF#to_html

=end

    def to_html
      retval = ""

      pre_tag = false
      self.to_s.split.each do |line|
        if line =~ (/\APRE/) then
          retval << '<pre>'
          pre_tag = true
          next
        elsif line =~ (/\A\/PRE/) then
          retval << '</pre>'
          pre_tag = false
          next
        end

        if pre_tag then
          retval << CGI.escapeHTML(line)
        else
          if line =~ (/\AOK/) then
            next
          elsif line =~ (/\A(TENKI|WEATHER|BASHO|LOCATION|TAIJU|WEIGHT|TAION|TEMPERATURE|SUIMIN|SLEEP|BGM|HOSU|STEP|HON|BOOK|KITAKU|HOMECOMING|WALK|RUN)\s+(.+)/) then
            next
          elsif line =~ (/\ASUB\s+(.+)/) then
            retval << sprintf("<p><b>%s</b>:", $1)
            next
          elsif line =~ (/\ALSUB\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
            retval << sprintf("<p><b><a href=\"%s://%s\">%s</a></b>", $1, $2, $3)
            next
          elsif line =~ (/\ALINK\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
            retval << sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
            next
          elsif line =~ (/\AL?IMG\s+(l|r|n)\s+(\S+)\.(jpg|jpeg|gif|png)/i) then
            line = $2
            if $1 == 'l' then
              retval << sprintf("<img align=\"left\" src=\"%s.%s\">", $2, $3)
            elsif $1 == 'r' then
              retval << sprintf("<img align=\"right\" src=\"%s.%s\">", $2, $3)
            else
              retval << sprintf("<img src=\"%s.%s\">", $2, $3)
            end
          end
          if line =~ (/\A~/) then
            retval << '<br>'
            next
          elsif line =~ (/\A(\/)?(UL|P|OL|DL)/) then
            retval << sprintf("<%s%s>", $1, $2)
            next
          elsif line =~ (/\A(\/)?(CITE)/) then
            unless $1 then
              retval << sprintf("<p><%s>", $2)
            else
              retval << sprintf("<%s%s></p>", $1, $2)
            end
            next
          elsif line =~ (/\ALI\s+(.+)/) then
            retval << sprintf("<li>%s", $1)
            next
          elsif line =~ (/\ALI/) then
            retval << '<li>'
            next
          end
        end
      end

      return retval
    end # def to_html

  end # module HNF

end # module DonRails
