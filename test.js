$(document).ready(function () {
	$("#newPortfolioSubmit").click(function(){
	    var newPortfolioName = document.getElementById("newPortfolioName").value;
	    var newURL='test.pl?act=createNewPortfolio&newPortfolioName='
	    newURL=newURL.concat(newPortfolioName)
	    window.location.href=newURL;
	});
});

DeleteClicked = function() {

}