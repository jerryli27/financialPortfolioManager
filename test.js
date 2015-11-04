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
        alert(document.getElementById("newTransactionDatetimePicker").getDate().unix());
        var dateString=document.getElementById("newTransactionDatetimePicker").getDate().val();
        var timeStamp=Date.parse(dateString).getTime()/1000;
        alert(timeStamp);
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
            url: 'test.pl',
            data: { 'act': 'newTranaction', 'symbol':document.getElementById("symbol").value,'price':document.getElementById("price").value,
            'amount':document.getElementById("amount").value,'method':method,
            'timestamp':timeStamp,
             'currPortfolioName':document.getElementById("currPortfolioName").innerHTML},
            }).done(function( msg ) {
                alert( "Data Received: " + msg );
        });
    });
});

DeleteClicked = function() {

}