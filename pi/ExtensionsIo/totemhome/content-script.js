var divmain=document.createElement("div");


divmain.setAttribute( 'id', "totemmenupopup");
divmain.setAttribute('hidden', true);
divmain.setAttribute('style', "position:fixed; z-index: 11; top:0px; height: 100%; width: 60px; display:block; background-color: rgba(80,80,80,0.2);" );
divmain.setAttribute( 'onmouseleave', "document.getElementById('totemmenupopup').hidden=true;");


var divover=document.createElement("div");

divover.setAttribute( 'id', "totemmenupopupover");
divover.setAttribute('style', "position:fixed; display:block; z-index: 10; top:0px; height: 100%; width: 20px; background-color: rgba(80,80,80,0.1);" );
divover.setAttribute( 'onmouseover', "document.getElementById('totemmenupopup').hidden=false;");
divover.setAttribute( 'onclick', "document.getElementById('totemmenupopup').hidden=false;");

var divchevr=document.createElement("div");
divchevr.setAttribute('style', "margin-top: 50vh; transform: translateY(-50%);");
divover.appendChild(divchevr);


var imgchevr = document.createElement("img");
var imgchevrURL = "chrome-extension://gbhobmgnfejlhkpmgbaeplppgkfnpkbn/images/chevron.png";
imgchevr.setAttribute('src', imgchevrURL);

var divhome=document.createElement("div");
divhome.setAttribute( 'id', "totemmenupopuphome");
divhome.setAttribute('style', "padding: 14px; padding-top:14%;");

var home = document.createElement("a");
home.setAttribute('href', "http://localhost:8080");
divhome.appendChild(home);

var imghome = document.createElement("img");
var imghomeURL = "chrome-extension://gbhobmgnfejlhkpmgbaeplppgkfnpkbn/images/icone_home_blanche.png";
imghome.setAttribute('src', imghomeURL);
home.appendChild(imghome);

var divtools=document.createElement("div");
divtools.setAttribute( 'id', "totemmenupopuptools");
divtools.setAttribute('style', "padding: 14px;");

var tools = document.createElement("a");
tools.setAttribute('href', "http://localhost:8080/config");
divtools.appendChild(tools);

var imgtools = document.createElement("img");
var imgtoolsURL = "chrome-extension://gbhobmgnfejlhkpmgbaeplppgkfnpkbn/images/icone_setting_blanc.png";
imgtools.setAttribute('src', imgtoolsURL);
tools.appendChild(imgtools);

var secret1 = document.createElement("div");
secret1.setAttribute('id', "totemmenupopupsecret1");
secret1.setAttribute('style', "height:14%; width:100%;");

var secret2 = document.createElement("div");
secret2.setAttribute('id', "totemmenupopupsecret2");
secret2.setAttribute('style', "height:100%; width:100%;");


divmain.appendChild(secret1);
divmain.appendChild(divhome);
divmain.appendChild(divtools);
divmain.appendChild(secret2);

document.body.appendChild(divmain);
document.body.appendChild(divover);
divchevr.appendChild(imgchevr);

var href = window.location.href.substring(0,10)
var secret=0

let divs = document.querySelectorAll("div");
Object.entries(divs).map(( object ) => {
    object[1].addEventListener("click", function(event) {
    console.log(this.id)
    if (this.id == "totemmenupopupsecret1"){
        event.stopPropagation();
    	if (secret== 2){
    		window.location = "http://localhost:8080/private/settings";
    	} else if (secret==0){
    		secret=1;
    	}
    }
    else if ((this.id == "totemmenupopupsecret2" && secret ==1 )){
        event.stopPropagation();
    	secret=2;
    }
    else {
    	secret=0;
    }

    console.log(secret)
    });
});

