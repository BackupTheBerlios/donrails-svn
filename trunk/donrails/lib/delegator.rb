=begin

=Data Format Delegator

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

=end


module DonRails

=begin rdoc

== DonRails::DataFormatDelegator

=end

  class DataFormatDelegator
    class << self

=begin rdoc

=== DonRails::DataFormatDelegator#formatmap

=end

      def formatmap
        retval = {}

        pp = File.join('modules', '*rb')
        Dir.glob(pp).each do |fn|
          begin
            Kernel.load(fn)
            fmt = File.basename(fn).sub(/.rb\Z/, '').downcase
            modlist = []
            modlist.push(sprintf("DonRails::%s", fmt.upcase))
            modlist.push(sprintf("DonRails::%s", fmt.capitalize))

            catch(:map) do
              modlist.each do |m|
                ObjectSpace.each_object(Module)  do |k|
                  if k.ancestors.map{|n| n.to_s}.include?(m) then
                    retval[fmt] = m
                    throw(:map)
                  end
                end
              end
            end # catch
          rescue => e
          end
        end # Dir.glob
        retval['plain'] = 'DonRails::PlainText'

        return retval
      end # def formatmap

=begin rdoc

=== DonRails::DataFormatDelegator#formatlist

=end

      def formatlist
        m = DataFormatDelegator.formatmap

        return m.keys
      end # def formatlist

    end

=begin rdoc

=== DonRails::DataFormatDelegator#new(text, fmt)

=end

    def initialize(text, fmt)
      raise TypeError, sprintf("can't convert %s into String", text.class) unless text.kind_of?(String)
      raise TypeError, sprintf("can't convert %s into String", fmt.class) unless fmt.kind_of?(String)

      @text = text
      mod = nil

      if DataFormatDelegator.formatlist.include?(fmt) then
        mod = eval(DataFormatDelegator.formatmap[fmt])
      else
        mod = eval(DataFormatDelegator.formatmap['plain'])
      end
      @text.extend(mod)
    end # def initialize

=begin rdoc

=== DonRails::DataFormatdelegator#chomp_tags

=== DonRails::DataFormatDelegator#to_html

=end

    def method_missing(m, *args)
      if @text.respond_to?(m) then
        @text.__send__(m, *args)
      else
        raise NoMethodError, sprintf("undefined method `%s' for %s", m, self)
      end
    end # def method_missing

  end # class DataFormatDelegator

=begin rdoc

== DonRails::PlainText

=end

  module PlainText

=begin rdoc

=== DonRails::PlainText#chomp_tags

=end

    def chomp_tags
      return self.to_s.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end # def chomp_tags

=begin rdoc

=== DonRails::PlainText#to_html

=end

    def to_html
      return self.chomp_tags.gsub("\n", "<br>\n")
    end # def to_html

  end # module PlainText

end # module DonRails
