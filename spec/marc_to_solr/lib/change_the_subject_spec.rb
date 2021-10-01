# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain outdated subject headings, we need the ability
# to update them at index time to preferred terms.
RSpec.describe ChangeTheSubject do
  context "a replaced term" do
    let(:subject_term) { "Illegal Aliens" }

    it "suggests a replacement" do
      change_the_subject = described_class.new
      expect(change_the_subject.check_for_replacement(subject_term)).to eq "Undocumented Immigrants"
    end
  end

  context "a term that has not been replaced" do
    let(:subject_term) { "Daffodils" }

    it "returns the term unchanged" do
      change_the_subject = described_class.new
      expect(change_the_subject.check_for_replacement(subject_term)).to eq subject_term
    end
  end

  context "an array of subject terms" do
    let(:subject_terms) { ["Illegal Aliens", "Workplace Safety"] }
    let(:fixed_subject_terms) { ["Undocumented Immigrants", "Workplace Safety"] }

    it "changes only the subject terms that have been configured" do
      change_the_subject = described_class.new
      expect(change_the_subject.fix(subject_terms)).to eq fixed_subject_terms
    end
  end
end
