# frozen_string_literal: true

##
# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  class << self
    def terms_mapping
      @terms_mapping ||= config
    end

    ##
    # Given an array of subject terms, replace the ones that need replacing
    # @param [<String>] subject_terms
    # @return [<String>]
    def fix(subject_terms)
      return [] if subject_terms.nil?
      subject_terms = subject_terms.compact.reject(&:empty?)
      return [] if subject_terms.blank?
      subject_terms.map do |term|
        replacement = check_for_replacement(term)
        replacement unless replacement.empty?
      end.compact.uniq
    end

    ##
    # Given a term, check whether there is a suggested replacement. If there is, return
    # it. If there is not, return the term unaltered.
    # @param [String] term
    # @return [String]
    def check_for_replacement(term)
      subterms = term.split(SEPARATOR)
      subfield_a = subterms.first
      replacement = terms_mapping[subfield_a]
      return term unless replacement
      subterms.delete(subfield_a)
      subterms.prepend(replacement["replacement"])
      subterms.join(SEPARATOR)
    end

    private

      def config
        @config ||= config_yaml
      end

      def config_yaml
        begin
          change_the_subject_erb = ERB.new(IO.read(change_the_subject_config_file)).result(binding)
        rescue StandardError, SyntaxError => e
          raise("#{change_the_subject_config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
        end

        begin
          YAML.safe_load(change_the_subject_erb, aliases: true)
        rescue => e
          raise("#{change_the_subject_config_file} was found, but could not be parsed.\n#{e.inspect}")
        end
      end

      def change_the_subject_config_file
        File.join(File.dirname(__FILE__), 'change_the_subject', 'change_the_subject.yml')
      end
  end
end
