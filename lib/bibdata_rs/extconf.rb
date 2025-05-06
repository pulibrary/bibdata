# This file is responsible for building a Makefile that can be
# used by the rake-compiler gem to compile the Rust code.
require 'mkmf'
require 'rb_sys/mkmf'

module BibdataRs
  module Extconf
    def self.makefile
      create_rust_makefile 'bibdata_rs'
    end
  end
end

BibdataRs::Extconf.makefile
