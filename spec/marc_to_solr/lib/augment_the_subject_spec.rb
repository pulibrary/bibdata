# frozen_string_literal: true

require 'rails_helper'

##
# When our catalog records contain subject headings, that should be classified as
# Indigenous Studies, it adds that term.
RSpec.describe AugmentTheSubject, indexing: true do
  let(:ats) { described_class.new }

  context "subfield a's that match by themselves" do
    it "builds a list of terms from the csv" do
      subfields = described_class.parse_standalone_a
      expect(subfields).to be_kind_of(Hash)
      expect(subfields[:standalone_subfield_a].length).to eq 4654
    end

    it "caches a list of terms from the json" do
      expect(ats.standalone_subfield_a_terms).to be
      expect(ats.standalone_subfield_a_terms.length).to eq 4654
    end

    context "mismatched capitalization" do
      let(:subject_term) { 'Abipon Language' }

      it "matches subfield a" do
        expect(ats.subfield_a_match?(subject_term)).to eq true
      end
    end
  end

  context "when traject somehow gives bad data" do
    let(:subject_terms) { [''] }

    it "does not raise an error" do
      expect { ats.indigenous_studies?(subject_terms) }.not_to raise_error
    end
  end

  context "subfield x's that match by themselves" do
    it "caches a list of terms from the json" do
      expect(ats.standalone_subfield_x_terms).to be
      expect(ats.standalone_subfield_x_terms.length).to eq 10
    end

    context "only the subfield x is relevant" do
      let(:subject_terms) { ["Whatever#{SEPARATOR}Indian authors#{SEPARATOR}History"] }

      it "matches subfield x" do
        expect(ats.subfield_x_match?(subject_terms.first))
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "with mismatched capitalization" do
      let(:subject_terms) { ["Whatever#{SEPARATOR}Indian AUthors#{SEPARATOR}History"] }

      it "matches" do
        expect(ats.subfield_x_match?(subject_terms.first)).to eq true
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "no subfield is relevant" do
      let(:subject_terms) { ["Whatever#{SEPARATOR}History#{SEPARATOR}United States"] }

      it "does not match" do
        expect(ats.indigenous_studies?(subject_terms)).to eq false
      end
    end
  end

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
      expect(ats.subfield_a_match?(subject_terms.first)).to eq true
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

  context "non-standard characters" do
    context "with ampersands" do
      let(:subject_terms) { ["Navajo Nation, Arizona, New Mexico & Utah"] }

      it "is recognized" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end
    context "with quotation marks" do
      let(:subject_terms) { ['Behdzi Ahda" First Nation'] }
      it "is recognized" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end
    context "with parentheses in the subject heading" do
      let(:subject_terms) { ["Fort Apache Indian Reservation (Ariz.)"] }

      it "matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end
  end

  context "required subfields" do
    it "creates a list of terms with required subfields" do
      subfields = described_class.parse_required_subfields
      parsed_subfields = JSON.parse(subfields)
      expect(parsed_subfields).to be
      expect(parsed_subfields.keys.empty?).to be false
      expect(parsed_subfields.keys.first).to eq('Acadians')
      expect(parsed_subfields.values.first[0]).to match_array(["History", "Expulsion, 1755", "Nova Scotia"])
      expect(parsed_subfields["United States"].size).to eq(9)
      expect(parsed_subfields["United States"][3]).to match_array(["History", "Civil War, 1861-1865", "Participation, Indian"])
      expect(parsed_subfields["United States."]).to be

      us_expected = [["Antiquities"],
                     ["Armed Forces", "Indians"],
                     ["Civilization", "Indian influences"],
                     ["History", "Civil War, 1861-1865", "Participation, Indian"],
                     ["History", "French and Indian War, 1754-1763"],
                     ["History", "King George's War, 1744-1748"],
                     ["History", "King William's War, 1689-1697"],
                     ["History", "Queen Anne's War, 1702-1713"],
                     ["Politics and government", "1754-1763"]]
      expect(parsed_subfields["United States"]).to match_array(us_expected)
    end

    it "creates a cache of required subfields" do
      expect(ats.indigenous_studies_required).to be_kind_of(Hash)
      expect(ats.indigenous_studies_required[:acadians].first).to be_kind_of(Set)
    end
  end
  context "subfield ǂa with required trailing subfields" do
    context "subfield not present" do
      let(:subject_terms) { ["Alaska"] }

      it "does not match" do
        expect(ats.indigenous_studies?(subject_terms)).to eq false
      end
    end

    context "subfield is present" do
      let(:subject_terms) { ["Alaska#{SEPARATOR}Antiquities"] }

      it "matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "subfield has incorrect capitalization" do
      let(:subject_terms) { ["Alaska#{SEPARATOR}antiquities"] }

      it "still matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "subfield a has incorrect capitalization" do
      let(:subject_terms) { ["alaska#{SEPARATOR}antiquities"] }

      it "still matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end

      it "does not match subfield_a" do
        expect(ats.subfield_a_match?(subject_terms.first)).to eq false
      end
    end

    context "both relevant and irrelevant subfields are present" do
      let(:subject_terms) { ["Alaska#{SEPARATOR}Antiquities#{SEPARATOR}Whatever"] }
      it "matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "Subfield a with possible positive matches" do
      let(:subject_terms) { ["United States#{SEPARATOR}History#{SEPARATOR}King George's War, 1744-1748"] }
      it "matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end

    context "With one required subfield but not others" do
      let(:subject_terms) { ["United States#{SEPARATOR}History"] }
      it "matches" do
        expect(ats.subfield_a_with_required_subfields_match?(subject_terms.first)).to eq false
        expect(ats.indigenous_studies?(subject_terms)).to eq false
      end
    end

    context "Similar subfield a's" do
      let(:subject_terms) { ["United States.#{SEPARATOR}Army#{SEPARATOR}Indian troops"] }
      it "matches" do
        expect(ats.indigenous_studies?(subject_terms)).to eq true
      end
    end
  end
end
