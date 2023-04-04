# frozen_string_literal: true

# Generate hierarchical heading strings
# like German language—Foreign words and phrases
class HierarchicalHeading
  def initialize(field:, spec:, split_on_subfield:)
    @field = field
    @spec = spec
    @split_on_subfield = split_on_subfield
  end

  def to_s
    return unless any_subfields?
    compile_string
  end

  private

    def any_subfields?
      subfields.any?
    end

    def compile_string
      heading = Traject::Macros::Marc21.trim_punctuation(first_subfield.value)
      remaining_subfields.each do |subfield|
        heading << delimiter_for(subfield)
        heading << Traject::Macros::Marc21.trim_punctuation(subfield.value)
      end
      heading
    end

    def delimiter_for(subfield)
      @split_on_subfield.include?(subfield.code) ? SEPARATOR : ' '
    end

    def first_subfield
      subfields.first
    end

    def remaining_subfields
      subfields.drop(1)
    end

    def subfields
      @subfields ||= @field.subfields.select { |subfield| @spec.subfields.include? subfield.code }
    end
end
