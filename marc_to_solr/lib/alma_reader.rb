# Alma MARC-XML files have no namespace defined, so we have to bypass that
# requirement in Nokogiri.
class AlmaReader < Traject::MarcReader
  def internal_reader
    @modified_internal_reader ||=
      begin
        result = super
        result.singleton_class.alias_method :old_start_element_namespace, :start_element_namespace
        # Redefine start_element_namespace to set the @ns to just be whatever
        # the URI is. For MARC records it's always the same anyways.
        result.singleton_class.define_method(:start_element_namespace) do |name, attributes = [], prefix = nil, uri = nil, ns = {}|
          @ns = uri
          old_start_element_namespace(name, attributes, prefix, uri, ns)
        end
        result
      end
  end
end
