require 'application_system_test_case'

class GoogleSSOTest < ApplicationSystemTestCase
  describe 'access top page' do
    before do
      mock_omniauth
    end

    it 'can sign in with Google Auth Account' do
      puts 'accept test ran'
      @user = create :user, email: 'test@gmail.com'
      visit root_path
      wait_for_element 'Sign in with Google'
      click_link 'Sign in with Google'

      take_screenshot
      assert has_content? @user.name
      take_screenshot
    end

    it 'will reject sign ins if email is not associated with a user' do
      puts 'reject test ran'
      visit root_path
      assert has_content? 'Sign in'
      click_link 'Sign in with Google'

      assert has_content? 'Sign in'
    end
  end
end
