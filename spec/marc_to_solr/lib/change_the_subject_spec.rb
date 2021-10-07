# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain outdated subject headings, we need the ability
# to update them at index time to preferred terms.
RSpec.describe ChangeTheSubject do
  context "a replaced term" do
    let(:subject_term) { "Illegal aliens" }

    it "suggests a replacement" do
      expect(described_class.check_for_replacement(subject_term)).to eq "Undocumented immigrants"
    end
  end

  context "a term that has not been replaced" do
    let(:subject_term) { "Daffodils" }

    it "returns the term unchanged" do
      expect(described_class.check_for_replacement(subject_term)).to eq subject_term
    end
  end

  context "an array of subject terms" do
    let(:subject_terms) { ["Illegal aliens", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants", "Workplace safety"] }

    it "changes only the subject terms that have been configured" do
      expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
    end
  end

  context "subject terms with subheadings" do
    let(:subject_terms) { ["Illegal aliens#{SEPARATOR}United States.", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants#{SEPARATOR}United States.", "Workplace safety"] }

    it "changes subfield a and re-assembles the full subject heading" do
      expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
    end
  end
end
