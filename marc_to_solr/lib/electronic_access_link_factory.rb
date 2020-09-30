
class ElectronicAccessLinkFactory
  # Extract values from a given MARC subfield
  # @param s_field the MARC subfield
  # @return [Hash] the extracted values
  def self.parse_subfield(s_field)
    anchor_text = ''

    holding_id = s_field.value if s_field.code == '0'

    # e. g. http://arks.princeton.edu/ark:/88435/7d278t10z, https://drive.google.com/open?id=0B3HwfRG3YqiNVVR4bXNvRzNwaGs
    url_key = s_field.value if s_field.code == 'u'

    # e. g. "Curatorial documentation"
    z_label = s_field.value if s_field.code == 'z'

    anchor_text = s_field.value if s_field.code == 'y' || s_field.code == '3' || s_field.code == 'x'

    values = { holding_id: holding_id, url_key: url_key, z_label: z_label, anchor_text: anchor_text }
    values.delete_if { |_key, value| value.nil? }
    values
  end

  # Extract values from an entire set of MARC subfields
  # @param marc_field the MARC record
  # @return [Hash] the values
  def self.parse_subfields(marc_field)
    subfield_values = marc_field.subfields.map { |subfield| parse_subfield(subfield) }
    subfield_values = subfield_values.empty? ? [{}] : subfield_values
    output = subfield_values.reduce(:merge)

    anchor_texts = subfield_values.map { |subfield_value| subfield_value[:anchor_text] }.reject { |subfield_value| subfield_value.nil? || subfield_value.empty? }
    output[:anchor_text] = anchor_texts.reduce { |u, v| u + "#{u}: #{v}" } unless anchor_texts.empty?

    output
  end

  # Constructs an ElectronicAccessLink object given a MARC record
  # @param marc_field the MARC record
  # @return ElectronicAccessLink
  def self.build(bib_id:, marc_field:)
    link_args = { bib_id: bib_id, holding_id: nil, url_key: nil, z_label: nil, anchor_text: nil }
    parsed_args = parse_subfields(marc_field)
    link_args.merge! parsed_args

    ElectronicAccessLink.new(link_args)
  end
end
