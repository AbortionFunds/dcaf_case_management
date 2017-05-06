require 'test_helper'

class DashboardLinkTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    log_in_as @user
  end

  describe 'visiting the dashboard' do
    it 'should not display the dashboard link' do
      visit authenticated_root_path
      wait_for_element 'Sign out'
    end
  end

  describe 'visiting a page other than the dashboard' do
    before do
      @patient = create :patient
      visit edit_patient_path(@patient)
      wait_for_element 'Patient information'
    end

    it 'should display the dashboard link' do
      assert has_link? 'Dashboard', href: authenticated_root_path
    end

    it 'should direct the user to the dashboard' do
      find('a', text: 'Dashboard').click
      wait_for_element 'Build your call list'
      assert_equal current_path, authenticated_root_path
      refute has_link? 'Dashboard', href: authenticated_root_path
    end
  end
end
