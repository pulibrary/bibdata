# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain outdated subject headings, we need the ability
# to update them at index time to preferred terms.
RSpec.describe ChangeTheSubject do
  context "a replaced term" do
    it "suggests a replacement" do
      expect(described_class.check_for_replacement("Illegal aliens")).to eq "Undocumented immigrants"
      expect(described_class.check_for_replacement("Alien criminals")).to eq "Noncitizen criminals"
      expect(described_class.check_for_replacement("Aliens")).to eq "Noncitizens"
      expect(described_class.check_for_replacement("Aliens in art")).to eq "Noncitizens in art"
      expect(described_class.check_for_replacement("Aliens in literature")).to eq "Noncitizens in literature"
      expect(described_class.check_for_replacement("Aliens in mass media")).to eq "Noncitizens in mass media"
      expect(described_class.check_for_replacement("Church work with aliens")).to eq "Church work with noncitizens"
      expect(described_class.check_for_replacement("Officials and employees, Alien")).to eq "Officials and employees, Noncitizen"
      expect(described_class.check_for_replacement("Aliens (Greek law)")).to eq "Noncitizens (Greek law)"
      expect(described_class.check_for_replacement("Aliens (Roman law)")).to eq "Noncitizens (Roman law)"
      expect(described_class.check_for_replacement("Child slaves")).to eq "Enslaved children"
      expect(described_class.check_for_replacement("Indian slaves")).to eq "Enslaved indigenous peoples"
      expect(described_class.check_for_replacement("Older slaves")).to eq "Enslaved older people"
      expect(described_class.check_for_replacement("Slaves")).to eq "Enslaved persons"
      expect(described_class.check_for_replacement("Women slaves")).to eq "Enslaved women"
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

  context "handles empty and nil terms" do
    let(:subject_terms) { ["", nil, "", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Workplace safety"] }

    it "return only non-empty terms" do
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
