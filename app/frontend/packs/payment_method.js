  // update value of payment field based on product selected
  // ensure payment method if fitternity if price is fitternity
  $(function() {

      $("select#purchase_price_id").on("change", function() {
        selection = document.getElementById("purchase_price_id");
        fitternity = false;
        selection_text = selection.options[selection.selectedIndex].text;
        if (selection_text.substring(0,10) == 'Fitternity') {
          // fitternity = true
          var q = document.getElementById('purchase_payment_mode');
          q.selectedIndex = 7;
        }
          // $.ajax({
          //     url:  '/products/payment',
          //     type: 'post',
          //     data: { selected_price: selection.value, fitternity: fitternity }
          // });
      });
  });
