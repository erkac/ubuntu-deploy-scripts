var webPage = require('webpage');


var i =500000;
var url = 'http://DOMAIN'

var j;
for(j=0;j<15;j++){


run_thread()

}

function run_thread()
{
	var page = webPage.create();
	var rand_ip = ''+Math.floor( Math.random()*254 )+'.'+Math.floor( Math.random()*254 )+'.'+Math.floor( Math.random()*254 )+'.'+Math.floor( Math.random()*254 )
	//var rand_ip =''
	page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.6 Safari/537.11";
	page.customHeaders = {
	  

	  "X-Forwarded-For": rand_ip
	};
	openurl(url,page);
}



function openurl(url,page){
	
	page.open(url, function(status) {
	if(0)
	{
	  page.evaluate(function() {
		  console.log(document.title) ;
		   });
	}
	  console.log(page.title); // get page Title
	  if(i==1){page.render('screen.png');
	  phantom.exit();
	  }
	   i--;
	   if (i%100==0)
	   {
	   	run_thread()
	   }
	   else{
	   	openurl(url,page)
	   }
	   
	  	
	});
}
