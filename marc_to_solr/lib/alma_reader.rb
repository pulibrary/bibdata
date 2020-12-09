class AlmaReader < Traject::MarcReader
  def internal_reader
    @modified_internal_reader ||=
      begin
        result = super
        super.instance_variable_set(:@ns, nil)
        result
      end
  end
end
