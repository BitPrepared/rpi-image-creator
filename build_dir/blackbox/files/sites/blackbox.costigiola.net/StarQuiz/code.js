onEvent("buttonPlay", "click", function( ) {
  setScreen("schermo1");
});
onEvent("buttonRestart1", "click", function( ) {
	setText("dropdown1", "");
	setText("dropdown2", "");
	setText("dropdown3", "");
	setText("dropdown4", "");
	setText("dropdown5", "");
	setText("dropdown6", "");
	setScreen("schermoPrincipale");
});
onEvent("buttonRestart2", "click", function( ) {
	setText("dropdown1", "");
	setText("dropdown2", "");
	setText("dropdown3", "");
	setText("dropdown4", "");
	setText("dropdown5", "");
	setText("dropdown6", "");
	setScreen("schermoPrincipale");
});
onEvent("buttonConferma1", "click", function( ) {
	if(getText("dropdown1") == "Tatooine") {
	  setScreen("schermo2");
	} else {
	  setScreen("schermoPerdita");
	}
});
onEvent("buttonConferma2", "click", function( ) {
	if(getText("dropdown2") == "Droide Astromeccanico") {
	  setScreen("schermo3");
	} else {
	  setScreen("schermoPerdita");
	}
});

onEvent("buttonConferma3", "click", function( ) {
	if(getText("dropdown3") == "Wookiee") {
	  setScreen("schermo4");
	} else {
	  setScreen("schermoPerdita");
	}
});
onEvent("buttonConferma4", "click", function( ) {
	if(getText("dropdown4") == "900") {
	  setScreen("schermo5");
	} else {
	  setScreen("schermoPerdita");
	}
});
onEvent("buttonConferma5", "click", function( ) {
	if(getText("dropdown5") == "Obi-Wan Kenobi") {
	  setScreen("schermo6");
	} else {
	  setScreen("schermoPerdita");
	}
});
onEvent("buttonConferma6", "click", function( ) {
	if(getText("dropdown6") == "Ahch-To") {
	  setScreen("schermoVittoria");
	} else {
	  setScreen("schermoPerdita");
	}
});
