# frozen_string_literal: true

require 'rails_helper'

describe 'accessibility', type: :feature, js: true do
  context 'home page' do
    before do
      visit '/'
    end

    it 'complies with wcag' do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('a[href$="events"]')
        .excluding('a[href$="delivery_locations"]')
        .excluding('a[href$="holding_locations"]')
        .excluding('a[href$="libraries"]')
        .excluding('.deployment-version')
        .excluding('span')
        .excluding('.form-group')
        .excluding('input[value="1"][name="holdings_only"][type="hidden"]')
        .excluding('a[rel="nofollow"]')
    end
  end
end
