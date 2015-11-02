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
                         'currPortfolioName':document.getElementById("currPortfolioName").value },
                        }).done(function( msg ) {
                        	alert( "Data Saved: " + msg );
                    });
	    // var cashDepositAmount = document.getElementById("cashDepositAmount").value;
	    // var newURL='test.pl?act=cashDeposit&cashDepositAmount=';
	    // newURL=newURL.concat(cashDepositAmount);
	    // window.location.href=newURL;
	});
});

DeleteClicked = function() {

}