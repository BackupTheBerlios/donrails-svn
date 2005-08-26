=begin

=RD file format parser

 Copyright (C) 2005 Akira TAGOH <at@gclab.org>

 You can redistribute it and/or modify it under the same term as GPL2 or later.

=end

require 'rd/rdfmt'
require 'rd/rd2html-lib'


module DonRails

=begin rdoc

== RD

=end

  module RD
    include DonRails::PlainText

    def self.extend_object(obj)
      super

      obj.instance_variable_set(:@_rd_visitor, nil)
      if $Visitor_Class then
        obj.instance_variable_set(:@_rd_visitor, $Visitor_Class.new)
      end
    end # def extend_object

=begin rdoc

=== DonRails::RD#to_html

=end

    def to_html
      src = sprintf("=begin\n%s=end\n", self.to_s)
      tree = ::RD::RDTree.new(src)
      retval = @_rd_visitor.visit(tree)

      return retval.gsub(/.*<body>(.*)/m, '\1').gsub(/(.*)<\/body>.*/m, '\1').sub(/\A\n/,'').chomp
    end # def to_html

  end # module RD

end # module DonRails
