# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain subject headings, that should be classified as
# Indigenous Studies, it adds that term.
RSpec.describe AugmentTheSubject do
  let(:ats) { described_class.new }

  context "subject terms about Indigenous people" do
    let(:subject_terms) { ["Indians of North America#{SEPARATOR}Connecticut", "Quinnipiac Indians."] }

    it "are recognized" do
      expect(ats.indigenous_studies?(subject_terms)).to eq true
    end

    it "adds Indigenous Studies as a subject" do
      expect(ats.add_indigenous_studies(subject_terms)).to eq subject_terms << "Indigenous Studies"
    end
  end

  context "subject term that are not relevant" do
    let(:subject_terms) { ["Daffodils", "Tulips"] }

    it "does not add Indigenous Studies as a subject" do
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
end
