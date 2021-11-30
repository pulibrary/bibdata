# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain subject headings, that should be classified as
# Indigenous studies, it adds that term.
RSpec.describe AugmentTheSubject do
  let(:ats) { described_class.new }

  context "subject terms about Indigenous people" do
    let(:subject_terms) { ["Indians of North America#{SEPARATOR}Connecticut", "Quinnipiac Indians."] }

    it "are recognized" do
      expect(ats.indigenous_studies?(subject_terms)).to eq true
    end

    it "adds Indigenous studies as a subject" do
      expect(ats.add_indigenous_studies(subject_terms)).to eq subject_terms << "Indigenous studies"
    end
  end

  context "subject term that are not relevant" do
    let(:subject_terms) { ["Daffodils", "Tulips"] }

    it "does not add Indigenous studies as a subject" do
      expect(ats.indigenous_studies?(subject_terms)).to eq false
    end
  end

  context "mismatched capitalization" do
    let(:subject_terms) { ["Indians OF NORTH America#{SEPARATOR}Connecticut", "Quinnipiac Indians."] }

    it "matches anyway" do
      expect(ats.indigenous_studies?(subject_terms)).to eq true
    end
  end

  context "mismatched punctuation" do
    let(:subject_terms) { ["Quinnipiac Indians."] }

    it "matches anyway" do
      expect(ats.indigenous_studies?(subject_terms)).to eq true
    end
  end

  context "normalizing lcsh terms" do
    it "replaces ǂz with SEPARATOR" do
      lcsh_term = "Indian architecture ǂz North America"
      expect(ats.normalize(lcsh_term)).to eq "indian architecture#{SEPARATOR}north america"
    end
  end

  context "subfield ǂa matches with trailing subfields" do
    let(:subject_terms) { ["Quinnipiac Indians#{SEPARATOR}History"] }

    it "matches anyway" do
      expect(ats.indigenous_studies?(subject_terms)).to eq true
    end
  end

  context "initial setup" do
    it "parses the raw list of subjects into subfields" do
      subfields = described_class.parse_subjects
      expect(subfields.keys).to match_array [:a, :x, :y, :z]
      expect(subfields[:a].count).to eq 1341
    end
  end
end
