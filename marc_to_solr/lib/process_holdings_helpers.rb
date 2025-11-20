# frozen_string_literal: true

class ProcessHoldingsHelpers
  attr_reader :record, :marc_breaker

  def initialize(record:, marc_breaker:)
    @record = record
    @marc_breaker = marc_breaker
  end

  def holding_id(field_852)
    BibdataRs::Marc.holding_id(marc_breaker_field(field_852), marc_breaker)
  end

  def alma?(field_852)
    BibdataRs::Marc.alma_code_start_22?(field_852['8'].to_s)
  end

  def scsb?(field_852)
    BibdataRs::Marc.is_scsb?(marc_breaker) && field_852['0']
  end

  def group_866_867_868_on_holding_perm_id(holding_perm_id, field_852)
    if scsb?(field_852)
      record.fields('866'..'868').select { |f| f['0'] == holding_perm_id }
    else
      record.fields('866'..'868').select { |f| f['8'] == holding_perm_id }
    end
  end

  def items_by_852(field_852)
    holding_id = holding_id(field_852)
    items = record.fields('876').select { |f| f['0'] == holding_id }
    items.map { |item| item unless private_scsb_item?(item, field_852) }.compact
  end

  def private_scsb_item?(field_876, field_852)
    field_876['x'] == 'Private' && scsb?(field_852)
  end

  # Select 852 fields from an Alma or SCSB record
  # returns an array of MARC 852 (full holdings) fields
  def fields_852_alma_or_scsb
    record.fields('852').select do |f|
      BibdataRs::Marc.alma_code_start_22?(f['8'].to_s) || (BibdataRs::Marc.is_scsb?(marc_breaker) && f['0'])
    end
  end

  # Build the current location code from 876$y and 876$z
  def current_location_code(field_876)
    marc_breaker_876 = marc_breaker_field(field_876)
    BibdataRs::Marc.current_location_code(marc_breaker_876)
  end

  # Build the permanent location code from 852$b and 852$c
  # Do not append the 852c if it is a SCSB - we save the SCSB locations as scsbnypl and scsbcul
  def permanent_location_code(field_852)
    marc_breaker_852 = marc_breaker_field(field_852)
    BibdataRs::Marc.permanent_location_code(marc_breaker_852)
  end

  # Select 876 fields (items) with permanent location. 876 location is equal to the 852 permanent location.
  def select_permanent_location_876(group_876_fields, field_852)
    return group_876_fields if /^scsb/.match?(field_852['b'])

    group_876_fields.select do |field_876|
      !in_temporary_location(field_876, field_852)
    end
  end

  # Select 876 fields (items) with current location. 876 location is NOT equal to the 852 permanent location.
  def select_temporary_location_876(group_876_fields, field_852)
    return [] if /^scsb/.match?(field_852['b'])

    group_876_fields.select do |field_876|
      in_temporary_location(field_876, field_852)
    end
  end

  def in_temporary_location(field_876, field_852)
    # temporary location is any item whose 876 and 852 do not match
    BibdataRs::Marc.current_location_code(marc_breaker_field(field_876)) != BibdataRs::Marc.permanent_location_code(marc_breaker_field(field_852))
  end

  def build_call_number(field_852)
    BibdataRs::Marc.build_call_number(marc_breaker_field(field_852))
  end

  def includes_only_private_scsb_items?(field_852)
    return false unless scsb?(field_852)

    BibdataRs::Marc.private_items?(marc_breaker, holding_id(field_852))
  end

  # Builds the holding, without any item-specific information
  # @returns [Hash]
  def build_holding(field_852, field_876 = nil, permanent:)
    holding = {}
    if permanent
      holding['location_code'] = permanent_location_code(field_852)
      holding['location'] = Traject::TranslationMap.new('locations', default: '__passthrough__')[holding['location_code']]
      holding['library'] = Traject::TranslationMap.new('location_display', default: '__passthrough__')[holding['location_code']]
    else
      holding['location_code'] = current_location_code(field_876)
      holding['current_location'] = Traject::TranslationMap.new('locations', default: '__passthrough__')[holding['location_code']]
      holding['current_library'] = Traject::TranslationMap.new('location_display', default: '__passthrough__')[holding['location_code']]
    end

    holding['call_number'] = build_call_number(field_852)
    holding['call_number_browse'] = build_call_number(field_852)
    # Updates current holding key; values are from 852
    if field_852['k']
      holding['sub_location'] = []
      holding['sub_location'] << field_852['k']
    end
    if field_852['l']
      holding['shelving_title'] = []
      holding['shelving_title'] << field_852['l']
    end
    if field_852['z']
      holding['location_note'] = []
      holding['location_note'] << field_852['z']
    end
    holding
  end

  # Build the items array in all_holdings hash
  def holding_items(value:, all_holdings:, item:)
    if all_holdings[value].present?
      all_holdings[value]['items'] ||= []
      all_holdings[value]['items'] << item
    end
    all_holdings
  end

  def build_item(field_852:, field_876:)
    is_scsb = scsb?(field_852)
    item = {}
    item[:holding_id] = field_876['0'] if field_876['0']
    item[:description] = field_876['3'] if field_876['3']
    item[:id] = field_876['a'] if field_876['a']
    item[:status_at_load] = field_876['j'] if field_876['j']
    item[:barcode] = field_876['p'] if field_876['p']
    item[:copy_number] = field_876['t'] if field_876['t']
    item[:use_statement] = field_876['h'] if field_876['h'] && is_scsb
    item[:storage_location] = field_876['l'] if field_876['l'] && is_scsb
    if field_876['x']
      if is_scsb
        item[:cgd] = field_876['x']
      else
        item[:process_type] = field_876['x']
      end
    end
    item[:collection_code] = field_876['z'] if field_876['z'] && is_scsb
    item
  end

  def process_866_867_868_fields(fields:, all_holdings:, holding_id:)
    fields.each do |field|
      all_holdings[holding_id]['location_has'] ||= []
      all_holdings[holding_id]['supplements'] ||= []
      all_holdings[holding_id]['indexes'] ||= []
      all_holdings[holding_id]['location_has'] << parse_textual_holdings(field, '866')
      all_holdings[holding_id]['supplements'] << parse_textual_holdings(field, '867')
      all_holdings[holding_id]['indexes'] << parse_textual_holdings(field, '868')
    end
    all_holdings
  end

  def parse_textual_holdings(field, field_tag)
    textual_holdings = []
    textual_holdings << field['a'] if field.tag == field_tag && field['a']
    textual_holdings << field['z'] if field.tag == field_tag && field['z']
    textual_holdings.join(' ') if textual_holdings.present?
  end

  private

    # Convert a Marc::Datafield to a string so that we can send it to the Rust marctk
    # The string will look like: =245 \\ $aMy title $b My subtitle
    def marc_breaker_field(field)
      MarcBreaker.new('').datafield_to_breaker(field)
    end
end
