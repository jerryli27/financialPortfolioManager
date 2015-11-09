$(document).ready(function () {
	
    $("#automaticStockTradingSubmit").click(function(){
        var symbol=param(symbol);
        if (symbol==null)
            symbol="AAPL";
        
        $.ajax({
            type: 'POST',
            url: 'shannon_ratchet_for_browser.pl',
            data: { 'act': 'newTranaction', 'initialcash':document.getElementById("initialcash").value,'tradingcost':document.getElementById("tradingcost").value,
             'symbol':symbol},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });

});

function param(val) {
    var result = null,
        tmp = [];
    location.search
    //.replace ( "?", "" ) 
    // this is better, there might be a question mark inside
    .substr(1)
        .split("&")
        .forEach(function (item) {
        tmp = item.split("=");
        if (tmp[0] === val) result = decodeURIComponent(tmp[1]);
    });
    return result;
}