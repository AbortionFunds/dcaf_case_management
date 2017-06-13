require 'test_helper'

class ExternalPledgesHelperTest < ActionView::TestCase
  describe 'options generators' do
    before { @options = external_pledge_source_options }

    it 'should spit out an array of available other funds' do
      assert_includes @options, 'Baltimore Abortion Fund'
      assert @options.class == Array
    end

    it 'should include the whole list of options' do
      expected_external_pledges_array = [ "Baltimore Abortion Fund", 
        "Richmond Reproductive Freedom Project (RRFP)",
        "Blue Ridge Abortion Assistance Fund (BRAAF)",
        "Tiller Fund (NNAF)",
        "Carolina Abortion Fund", 
        "Women's Medical Fund (Philadelphia)",
        "NYAAF (New York)", 
        "Clinic discount", 
        "Other funds (see notes)" ]
      assert_same_elements @options, expected_external_pledges_array
    end

    it 'should remove preselected options' do
      @patient = create :patient
      create :external_pledge, source: 'Baltimore Abortion Fund',
                               amount: 100,
                               patient: @patient

      refute_includes available_pledge_source_options_for(@patient),
                      'Baltimore Abortion Fund'
      assert_includes available_pledge_source_options_for(@patient),
                      'NYAAF (New York)'
    end
  end
end
