$(function() {
    $("select#purchase_product_id").on("change", function() {
      ajax_call_to_purchases_discount_when_discount_or_product_changes()
    });
});

$(function() {
  $("select#purchase_renewal_discount_id").on("change", function() {
    ajax_call_to_purchases_discount_when_discount_or_product_changes()
  });
});

$(function() {
  $("select#purchase_status_discount_id").on("change", function() {
    ajax_call_to_purchases_discount_when_discount_or_product_changes()
  });
});

$(function() {
  $("select#purchase_oneoff_discount_id").on("change", function() {
    ajax_call_to_purchases_discount_when_discount_or_product_changes()
  });
});

$(function() {
  $("select#purchase_dop_1i").on("change", function() {
    ajax_call_to_purchases_dop_when_date_changes()
    setTimeout(function (){ ajax_call_to_purchases_discount_when_date_changes();},100)
  });
});

$(function() {
    $("select#purchase_dop_2i").on("change", function() {
      ajax_call_to_purchases_dop_when_date_changes()
      setTimeout(function (){ ajax_call_to_purchases_discount_when_date_changes();},100)      
    });
});
$(function() {
    $("select#purchase_dop_3i").on("change", function() {
      ajax_call_to_purchases_dop_when_date_changes()
      setTimeout(function (){ ajax_call_to_purchases_discount_when_date_changes();},100)      
    });
});

function ajax_call_to_purchases_discount_when_discount_or_product_changes() {
  $.ajax({
    url:  '/purchases/discount',
    type: 'get',
    data: { selected_renewal_discount_id: document.getElementById("purchase_renewal_discount_id").value || 0,
            selected_status_discount_id: document.getElementById("purchase_status_discount_id").value || 0,
            selected_oneoff_discount_id: document.getElementById("purchase_oneoff_discount_id").value || 0,
            selected_product_id: document.getElementById("purchase_product_id").value || 0 }
  });
}

function ajax_call_to_purchases_dop_when_date_changes() {
  $.ajax({
    url:  '/purchases/dop_change',
    type: 'get',
    data: { selected_renewal_discount_id: document.getElementById("purchase_renewal_discount_id").value || 0,
            selected_status_discount_id: document.getElementById("purchase_status_discount_id").value || 0,
            selected_oneoff_discount_id: document.getElementById("purchase_oneoff_discount_id").value || 0,
            selected_product_id: document.getElementById("purchase_product_id").value || 0,
            selected_dop_1i: document.getElementById("purchase_dop_1i").value,
            selected_dop_2i: document.getElementById("purchase_dop_2i").value,
            selected_dop_3i: document.getElementById("purchase_dop_3i").value }
  });
}

function ajax_call_to_purchases_discount_when_date_changes() {
  $.ajax({
    url:  '/purchases/discount',
    type: 'get',
    data: { selected_renewal_discount_id: document.getElementById("purchase_renewal_discount_id").value || 0,
            selected_status_discount_id: document.getElementById("purchase_status_discount_id").value || 0,
            selected_oneoff_discount_id: document.getElementById("purchase_oneoff_discount_id").value || 0,
            selected_product_id: document.getElementById("purchase_product_id").value || 0,
            selected_dop_1i: document.getElementById("purchase_dop_1i").value,
            selected_dop_2i: document.getElementById("purchase_dop_2i").value,
            selected_dop_3i: document.getElementById("purchase_dop_3i").value }
  })
}