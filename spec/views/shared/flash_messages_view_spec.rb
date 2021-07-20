# frozen_string_literal: true
require 'rails_helper'

describe 'shared/flash_messages', type: :view do
  it 'renders flash error partial if there is an error' do
    flash.now[:error] = ['Error 1', 'Error 2']
    render partial: 'shared/flash_messages'
    expect(response).to render_template(partial: 'shared/_error_flash_message')
  end

  it "doesn't render flash error partial for a flash notice" do
    flash.now[:notice] = 'A notice'
    render partial: 'shared/flash_messages'
    expect(response).not_to render_template(partial: 'shared/_error_flash_message')
  end

  it 'each flash error is rendered within an <li>' do
    flash.now[:error] = ['Error 1', 'Error 2']
    render partial: 'shared/flash_messages'
    flash.now[:error].each { |e| expect(response.body.include?("<li>#{e}</li>")).to eq true }
  end

  it 'renders flash notice message' do
    flash.now[:notice] = 'A notice'
    render partial: 'shared/flash_messages'
    expect(response.body.include?(flash.now[:notice])).to eq true
  end

  it 'renders flash success message' do
    flash.now[:success] = 'Success!'
    render partial: 'shared/flash_messages'
    expect(response.body.include?(flash.now[:success])).to eq true
  end

  it 'renders flash alert message' do
    flash.now[:alert] = 'Danger!'
    render partial: 'shared/flash_messages'
    expect(response.body.include?(flash.now[:alert])).to eq true
  end

  it 'renders flash message' do
    flash.now[:flash] = 'Flash'
    render partial: 'shared/flash_messages'
    expect(response.body.include?(flash.now[:flash])).to eq true
  end
end
