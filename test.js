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
            url: 'test.pl',
            data: { 'act': 'cashDeposit', 'cashDepositAmount':document.getElementById("cashDepositAmount").value,
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
            	alert( "Data Received: " + msg );
        });
	});
    $("#cashWithdrawSubmit").click(function(){
        $.ajax({
            type: 'POST',
            url: 'test.pl',
            data: { 'act': 'cashWithdraw', 'cashWithdrawAmount':document.getElementById("cashWithdrawAmount").value,
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
    $("#newTransactionSubmit").click(function(){
        alert( "Got it!");
        $.ajax({
            type: 'POST',
            url: 'test.pl',
            data: { 'act': 'newTranaction', 'symbol':document.getElementById("symbol").value,'price':document.getElementById("price").value,
            'amount':document.getElementById("amount").value,
            'newTransactionDatetimePicker':document.getElementById("newTransactionDatetimePicker").value, //////
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
});

DeleteClicked = function() {

}