# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
updateBalance = ->
  if $("#patient_pregnancy_procedure_cost").val()
    $(".outstanding-balance-ctn").removeClass('hidden')
    $("#outstanding-balance").text('$' + calculateRemainder())
  else
    $(".outstanding-balance-ctn").addClass('hidden')

calculateRemainder = ->
  total = valueToNumber $("#patient_pregnancy_procedure_cost").val()
  contributions = valueToNumber($("#patient_pregnancy_patient_contribution").val()) +
                  valueToNumber($("#patient_pregnancy_naf_pledge").val()) +
                  valueToNumber($("#patient_pregnancy_dcaf_soft_pledge").val()) +
                  valueToNumber($(".external_pledge_amount").toArray().reduce (acc, next) ->
                    acc + valueToNumber($(next).val())
                  , 0)
  total - contributions

valueToNumber = (val) ->
  +val || 0

getClinics = ->
  $.get '/get_clinics', (data, status) ->
    if status == 'success'
      $.when data

filterNAF = ->
  checked = $("#naf_filter").prop("checked")
  $("#patient_clinic_name > option").each ->
    if $(this).attr('data-naf') == "false"
      $(this).attr("disabled", checked)

mapNAFtoClinic = (deferred) ->
  $.each deferred, (index) ->
    name = deferred[index].responseJSON[0]
    accepts_naf = deferred[index].responseJSON[1]
    $('#patient_clinic_name > option[value=\'' + name + '\']').attr 'data-naf', accepts_naf

fetchClinicNAF = (data) ->
  deferred = []
  $.each data, (index) ->
    deferred.push $.ajax(
      url: '/fetch_clinic_naf'
      data:
        name: data[index][0]
      type: 'GET')
    return
  $.when.apply($, deferred).then(->
    mapNAFtoClinic(deferred)
    return
  ).fail(->
    console.log "failed to fetch clinic attributes"
    return
  )

ready = ->
  $(document).on "click", "#toggle-call-log", ->
    $(".old-calls").toggleClass("hidden")
    html = if $(".old-calls").hasClass("hidden") then "View all calls" else "Limit list"
    $("#toggle-call-log").html(html)

  $(document).on "change", ".edit_patient", ->
    $(this).submit()

  $(document).on "change", ".edit_external_pledge", ->
    $(this).submit()

  $(document).on "change", "#abortion-information-form input, #external_pledges input", ->
    updateBalance()

  $(document).on "click", "#create-external-pledge", ->
    # timeout to handle mongo updating and rails appending new field
    setTimeout(updateBalance, 500)

  $(document).on "click", "#naf_filter", ->
    attr = $('#patient_clinic_name > option').last().attr 'data-naf'
    if typeof attr == 'undefined'
      getClinics().then(fetchClinicNAF).then(filterNAF)
    else
      filterNAF()



  if $("#patient_pregnancy_procedure_cost").val()
    updateBalance()

  # put a help icon next to form field labels that have the "tooltip-header" class
  # the text that shows up in the tooltip is from the label's corresponding form field's "data-tooltip-text" attribute
  $( '.tooltip-header' ).append( ' <span class="tooltip-header-help">(?)</span>' )
  $( '.tooltip-header' ).parent( '.form-group' ).find( '.form-control' ).each ->
    $(@).parents( '.form-group' ).find( '.tooltip-header-help' ).tooltip( {
      html: true,
      placement: 'top',
      title: $(@).data( 'tooltip-text' )
    } )

$(document).on 'ready page:load', ready
