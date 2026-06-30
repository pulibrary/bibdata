# frozen_string_literal: true

require 'rails_helper'

describe 'accessibility', :axe, :js, type: :feature do
  context 'home page' do
    before do
      visit '/'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('.deployment-version')
    end
  end

  context 'events page' do
    before do
      visit '/events'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('.deployment-version')
    end
  end

  context 'delivery locations page' do
    before do
      visit '/locations/delivery_locations'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('.deployment-version')
        .excluding('.hasStickyHeaders')
    end
  end

  context 'holding locations page' do
    before do
      visit '/locations/holding_locations'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('.deployment-version')
        .excluding('.hasStickyHeaders')
    end
  end

  context 'libraries page' do
    before do
      visit '/locations/libraries'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('.deployment-version')
        .excluding('.hasStickyHeaders')
    end
  end
end
