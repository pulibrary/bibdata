# encoding: UTF-8
require 'rails_helper'

describe 'From geo.rb' do
  before(:all) do
    @indexer = IndexerService.build
  end

  describe '#decimal_coordinate format for dc:coverage' do
    before(:all) do
      @w = '-89'
      @e = '20.2355'
      @n = '25.221'
      @s = '-0.2444'
      @proper_034 = { "034" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "d" => @w }, { "e" => @e }, { "f" => @n }, { "g" => @s }] } }
      @bad_034 = { "034" => { "ind1" => " ", "ind2" => " ", "subfields" => [{ "d" => @w }, { "e" => @e }, { "f" => @n }, { "g" => 'blah' }] } }
      @good_bbox = MARC::Record.new_from_hash('fields' => [@proper_034])
      @bad_bbox = MARC::Record.new_from_hash('fields' => [@bad_034])
      @good_coverage = @indexer.send(:decimal_coordinate, @good_bbox)
      @bad_coverage = @indexer.send(:decimal_coordinate, @bad_bbox)
    end

    it 'returns dc:coverage formatted string for valid 034' do
      expect(@good_coverage).to eq "northlimit=#{@n}; eastlimit=#{@e}; southlimit=#{@s}; westlimit=#{@w}; units=degrees; projection=EPSG:4326"
    end
  end

  describe '#valid_coordinate_format?' do
    it 'returns true for decimal format' do
      expect(@indexer.send(:valid_coordinate_format?, '-89', {})).to eq(true)
    end
    it 'returns false for degree format' do
      expect(@indexer.send(:valid_coordinate_format?, 'N0820000', {})).to eq(false)
    end
    it 'returns false for unrecognized format' do
      expect(@indexer.send(:valid_coordinate_format?, 'mistake', {})).to eq(false)
    end
  end
end
