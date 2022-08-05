// In the purchase form, when a price is selected:
// 1) if a Fitternity price is selected, set the payment mode to Fitternity (which ensures the Purchase is associated with a Fitternity)
// 2) send an ajax request to the server which looks up the price and responds with some javascript to update the payment field
$(function() {
    $("select#purchase_price_id").on("change", function() {
      selection = document.getElementById("purchase_price_id");
      // fitternity = false;
      // https://stackoverflow.com/questions/14976495/get-selected-option-text-with-javascript
      selection_text = selection.options[selection.selectedIndex].text;
      if (selection_text.substring(0,10) == 'Fitternity') {
        // fitternity = true
        // Fitternity is the 7th payment method in constants.yml
        document.getElementById('purchase_payment_mode').selectedIndex = 7;
      }
        $.ajax({
            url:  '/products/payment',
            type: 'get',
            data: { selected_price: selection.value }
            // data: { selected_price: selection.value, fitternity: fitternity }
        });
    });
});

// syntax example with javascript rather than jquery
// document.getElementById("purchase_price_id").onchange =  function () {
// alert ("this is a test");
// }

prices = $('select#purchase_price_id').html()
// '<option value="1">DropIn</option>\n<option value="2">Fitternity Bulk</option>...</option>'
$('select#purchase_product_id').on('change', function() {
  product = $('#purchase_product_id :selected').text(); // 'Space Group 1C:1D'
  options = $(prices).filter("optgroup[label='" + product + "']").html();
  if (options) {
    $('#purchase_price_id').html(options);}
  else {
    $('#purchase_price_id').empty();
  }
  $.ajax({
      url:  '/products/payment',
      type: 'get',
      data: { selected_price: $("select#purchase_price_id").val()
     }
  });
 });

 $(document).ready(()=>{
   prices = $('select#purchase_price_id').html();
   product = $('#purchase_product_id :selected').text();
   options = $(prices).filter("optgroup[label='" + product + "']").html();
   if (options) {
     $('#purchase_price_id').html(options);}
   else {
     $('#purchase_price_id').empty();}
 });
