$(document).ready(function () {
	$("#newPortfolioSubmit").click(function(){
	    var newPortfolioName = document.getElementById("newPortfolioName").value;
	    var newURL='test.pl?act=createNewPortfolio&newPortfolioName=';
	    newURL=newURL.concat(newPortfolioName);
	    window.location.href=newURL;
	});
	
	$("#cashDepositSubmit").click(function(){
		$.ajax({
            type: 'POST',
            url: 'databaseActions.pl',
            data: { 'act': 'cashDeposit', 'cashDepositAmount':document.getElementById("cashDepositAmount").value,
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
            	alert( "Data Received: " + msg );
        });
	});
    $("#cashWithdrawSubmit").click(function(){
        $.ajax({
            type: 'POST',
            url: 'databaseActions.pl',
            data: { 'act': 'cashWithdraw', 'cashWithdrawAmount':document.getElementById("cashWithdrawAmount").value,
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
    $("#newTransactionSubmit").click(function(){
        var method;
        if (document.getElementById("newTransactionBuy").checked){
            method="b"
        }else if (document.getElementById("newTransactionSell").checked){
            method="s"
        }else{
            alert("Nothing is selected. What have you done to the radio buttons?!");
            return;
        }
        $.ajax({
            type: 'POST',
            url: 'databaseActions.pl',
            data: { 'act': 'newTranaction', 'symbol':document.getElementById("symbol").value,'price':document.getElementById("price").value,
            'amount':document.getElementById("amount").value,'method':method,
            'timestamp':$('#newTransactionDatetimeDiv').data("DateTimePicker").viewDate().unix(),
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
    $("#automaticStockTradingSubmit").click(function(){
        var symbol=param(symbol);
        if (symbol==null)
            symbol="AAPL";
        
        $.ajax({
            type: 'POST',
            url: 'databaseActions.pl',
            data: { 'act':'automaticStockTrade',initialcash':document.getElementById("initialcash").value,'tradingcost':document.getElementById("tradingcost").value,
             'symbol':symbol},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
});

DeleteClicked = function() {
    alert( "Deletion yet to be implemented");
}

// Function to get the parameters in the url. Behaves just like param in perl.
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