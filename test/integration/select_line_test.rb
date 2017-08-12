require 'test_helper'

class SelectLineTest < ActionDispatch::IntegrationTest
  before do
    Capybara.current_driver = :poltergeist
    @user = create :user
    log_in @user
  end

  describe 'line selection process' do
    it 'should redirect to line selection page on login' do
      assert_equal current_path, new_line_path
      assert has_content? 'DC'
      assert has_content? 'MD'
      assert has_content? 'VA'
      assert has_button? 'Select your line for this session'
    end

    it 'should redirect to the main dashboard after line set' do
      choose 'DC'
      click_button 'Select your line for this session'
      assert_equal current_path, authenticated_root_path
      assert has_content? 'Your current line: DC'
    end
  end

  # TODO
  describe 'line redirect on single line' do
    before do
      # TODO setup line array like so ['dc']
      @user.line='DC'
      # LINES=%w(DC).map(&:to_sym).freeze
      puts @user.inspect
      # how to change env var constants in this block?
    end

    it 'should redirect to the dashboard' do
      assert_equal current_path, authenticated_root_path
    end
  end

  describe 'redirection conditions' do
    before { @patient = create :patient }
    it 'should redirect from dashboard if no line is set' do
      visit edit_patient_path(@patient) # no redirect
      assert_equal current_path, edit_patient_path(@patient)
      visit authenticated_root_path # back to dashboard
      assert_equal current_path, new_line_path
    end
  end
end
