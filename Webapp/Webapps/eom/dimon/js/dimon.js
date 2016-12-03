/* ========================================================================= */
/* Program : dimon.js                                                        */
/* Purpose : Javascript for the EOM DI Monitor                               */
/*                                                                           */
/* Change History                                                            */
/* Date    By     Changes                                                    */
/* ------- ------ ---------------------------------------------------------- */
/* 28nov11 eombah initial version                                            */
/* 30aug12 eombah corrected ajax-loader images                               */
/* 20nov16 eombah updatd for dimon3                                          */
/* ========================================================================= */

//$('#navpath .navpath-item:last').attr('id')

var settings =	{                  urlSPA : ''
				,                  sproot : ''
				,                 imgroot : ''
				,            _gopt_device : ''
				,               _odsstyle : ''
				,             currentView : ''
				,               flowsmode : ''
				,        currentViewParms : ''
				,             currentPath : ''
				,    autorefresh_interval : 5
				//,     viewlog_maxfilesize : 
				,             filterFlows : 'all_flows_excl_hidden'
				,              filterJobs : 'all_jobs'
				,               sortFlows : ''
				,                sortJobs : ''
				};

var _debug;
var interval              =  0; // for javascript setInterval function
var autorefresh_intervals = [1,2,3,4,5,10,15,20,25,30,40,50,60,75,90,105,120,180,240,300,600,900,1200,1500,1800,2700,3600,7200,9999999];
var svgMenuNavbar = '<svg style="width:20px;height:20px" viewBox="0 0 24 24">'
					+'<path fill="#454545" d="M12,16A2,2 0 0,1 14,18A2,2 0 0,1 12,20A2,2 0 0,1 10'
					+',18A2,2 0 0,1 12,16M12,10A2,2 0 0,1 14,12A2,2 0 0,1 12,14A2,2 0 0,1 10,12A2'
					+',2 0 0,1 12,10M12,4A2,2 0 0,1 14,6A2,2 0 0,1 12,8A2,2 0 0,1 10,6A2,2 0 0,1 12,4Z" />'
					+'</svg>';

var filterFlowsMenuItems =	[ {'value':'running'        , 'text':'Running'       }
							, {'value':'completed'      , 'text':'Completed'     }
							, {'value':'failed'         , 'text':'Failed'        }
							, {'value':'all_excl_hidden', 'text':'All but hidden'}
							, {'value':'all'            , 'text':'All'           }
							];

var filterJobsMenuItems =	[ {'value':'running'  , 'text':'Running'  }
							, {'value':'completed', 'text':'Completed'}
							, {'value':'failed'   , 'text':'Failed'   }
							, {'value':'all'      , 'text':'Show all' }
							];

var sortFlowsMenuItems =	[ {'value':'trigger_time' , 'text':'Trigger time'}
							, {'value':'flow_job_name', 'text':'Flow'        }
							, {'value':'flow_run_id'  , 'text':'Flow Run ID' }
							, {'value':'start_dts'    , 'text':'Start time'  }
							, {'value':'end_dts'      , 'text':'End time'    }
							, {'value':'elapsed_time' , 'text':'Elapsed time'}
							];

var sortJobsMenuItems =		[ {'value':'job_seq_nr'   , 'text':'Flow/Job sequence number'}
							, {'value':'flow_job_name', 'text':'Flow/Job'    }
							, {'value':'job_run_id'   , 'text':'Job Run ID'  }
							, {'value':'start_dts'    , 'text':'Start time'  }
							, {'value':'end_dts'      , 'text':'End time'    }
							, {'value':'elapsed_time' , 'text':'Elapsed time'}
							];


// Close menu's on any click outside them */
$(document).click(function(event) {
	var target = event.target;
	while (target && !target.id) {
		target = target.parentNode;
	}
	if (target) {
		if( (target.id != 'menubuttonSort') && ($(target).closest("#menuSort").attr('id') != 'menuSort') ) {
			$('#menuSort').remove();
		}
		if( (target.id != 'menubuttonFilter') && ($(target).closest("#menuFilter").attr('id') != 'menuFilter') ) {
			$('#menuFilter').remove();
		}
		if( (target.id != 'menubuttonNavbar') && ($(target).closest("#menuNavbar").attr('id') != 'menuNavbar') ) {
			$('#menuNavbar').remove();
		}
	}
})


function setResults1Size() {
	var results1Height = $(window).height() - $("#dimon-menubar").height() - $("#dimon-navbar").height() - $("#dimon-footer").height() - 55;
	var results1Width  = $(window).width() - 35;
	$("#results1").height(results1Height);
	$("#results1").width(results1Width);
}//setResults1Size

function setViewLogContentSize(){
	var viewlogContentHeight = $(".ui-dialog").height() - $(".ui-dialog-titlebar").height() - $("#viewlogHeader").height() - $(".ui-dialog-buttonpane").height() - 60;
	$("#viewlogContent").height(viewlogContentHeight);
}//setViewLogContentSize

function setSearchSize(){
	var sortButtonLeft = $("#menubuttonSort").position().left;
	var searchLeft = $("#search").position().left;
	var searchWidth = Math.max(100,sortButtonLeft - searchLeft - 300);
	$("#search").width(searchWidth);
}//setSearchSize

$(window).resize(function() {
	setSearchSize();
	setResults1Size();
});


function keepAlive() {
  $.ajax({     type : "GET"
		 ,      url : settings.urlSPA
		 ,     data : { "_program" : getSPName('dimonKeepAlive')
					  }
		 ,    async : true
		 ,    cache : false
		 ,  timeout : 60000 /* in ms */
		 ,    error : function(XMLHttpRequest,textStatus,errorThrown) {
					   var r= confirm('dimonKeepAlive'
									+ '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									+ '\n\nClick OK to view the SAS log, Cancel to quit.');
					   if (r == true) {
						 showSasError(XMLHttpRequest.responseText);
					   }
					 }
		 });
}//keepAlive


// JQuery initialization
$(function() {

	// get settings from cookies
	settings.filterFlows          = ( Cookies.get('dimonFilterFlows')          == null ? 'all_excl_hidden'   : Cookies.get('dimonFilterFlows'        ) );
	settings.filterJobs           = ( Cookies.get('dimonFilterJobs' )          == null ? 'all'               : Cookies.get('dimonFilterJobs'         ) );
	settings.sortFlows            = ( Cookies.get('dimonSortFlows')            == null ? 'trigger_time desc' : Cookies.get('dimonSortFlows'          ) );
	settings.sortJobs             = ( Cookies.get('dimonSortJobs' )            == null ? 'job_seq_nr asc'    : Cookies.get('dimonSortJobs'           ) );
	settings.autorefresh_interval = ( Cookies.get('dimonAutoRefreshInterval' ) == null ? 5                   : Cookies.get('dimonAutoRefreshInterval') );

	$(document).tooltip();

	$("#dimon-logo").attr("src",settings.imgroot + '/dimon-logo.png'); // set logo
	$("#linkHome").click(function() {
		window.location.href = settings.urlSPA + '?_program=' + getSPName('dimon');
	});

	$('#search').button()
			    .keydown(function(event) {
					if(event.keyCode == 13) {
						refresh();
					}
				})
			  ;

	$("#menubuttonSettings").button({ icons: { primary: 'ui-icon-gear' }
									,  text: false
									})
							.click( function() { getSettings(); });

	$("#menubuttonFilter").button({ icons: { secondary: "ui-icon-triangle-1-s" } })
						  .click(function(event) {
							createFilterMenu();
							$("#menuFilter").show();
							});

	$("#menubuttonSort").button()
						.click(function(event) {
							createSortMenu();
						});

	// set #dimon-navbar height
	$("#dimon-navbar").html('<div style="margin:1.15em;"><span class="l systemtitle">&nbsp;</span><div>');

	_debug = ( getUrlParameter('_debug') != null ? getUrlParameter('_debug') : 0);

	var srun_date = '';
	var path = getUrlParameter('path');
	if (path) {
	} else {
		srun_date = $.datepicker.formatDate('ddMyy',new Date());
		path = '//_' + srun_date;
	}
	navigate(path); 
	setSearchSize();

	// Keep the Stored Process Server session alive by running the keepAlive Stored Process once every 5 minutes
	window.setInterval("keepAlive()",300000);

});


function getSettings() {

  var dialog = $( '<div id="dialogSettings">'
				+ '<p>'
				+ '<label for="autorefresh-interval" style="float:left">Auto-refresh interval:</label>'
				+ '<div id="slider-autorefresh-interval" style="float:left; width:400px; margin-left: 10px;"></div>'
				+ '<input type="text" id="autorefresh-interval" readonly style="border:0; float:left; margin-left: 10px;">'
				+ '</p>'
				+ '</div>').appendTo('body');
  dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					 close : function(event, ui) {
							   // remove div with all data and events
							   dialog.remove();
							 }
				,    title : 'Settings'
				,    width : 800
				,   height : 400
				,    modal : true
				,  buttons : { "Apply" : function(event, ui) {
											autorefresh_interval = $("#slider-autorefresh-interval").slider("value");
											settings.autorefresh_interval = autorefresh_interval;
											Cookies.set('dimonAutoRefreshInterval',settings.autorefresh_interval,{ expires: 365 });
											$(this).dialog('close');
											refresh();
                                         }
							 , "Close" : function(event, ui) {
										   $(this).dialog('close');
										 }
							 }
				});

	$("#slider-autorefresh-interval").slider({
		range: "min",
		value: settings.autorefresh_interval,
		min: 0,
		max: autorefresh_intervals.length - 1,
		step: 1,
		animate: true,
		slide: function( event, ui ) {
			if (ui.value == (autorefresh_intervals.length - 1)) {
				$("#autorefresh-interval").val("Don't auto-refresh");
			} else {
				$("#autorefresh-interval").val(autorefresh_intervals[ui.value] + ' seconds');
			}
		}
	});
	if ($("#slider-autorefresh-interval").slider("value") == (autorefresh_intervals.length - 1)) {
		$("#autorefresh-interval").val("Don't auto-refresh");
	} else {
		$("#autorefresh-interval").val(autorefresh_intervals[$("#slider-autorefresh-interval").slider("value")] + ' seconds');
	}

	$(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//getSettings


function updateFilterButtonLabel() {

	var filterLabel = '';

	switch (settings.currentView) {
		case "Flows":
			var menuItems = filterFlowsMenuItems;
			var filter    = settings.filterFlows;
			break;
		case "Jobs":
			var menuItems = filterJobsMenuItems;
			var filter    = settings.filterJobs;
			break;
		case "Steps":
			var menuItems = [];
			var filter    = '';
			break;
		default:
	}

	var filterLabel = '';
	for (i=0; i < menuItems.length; i++) {
		if (menuItems[i].value == filter) {
			filterLabel = menuItems[i].text;
		}
	}
	$("#menubuttonFilter").button({ label: 'Show: ' + filterLabel });

}//updateFilterButtonLabel


function updateSortButtonLabel() {

	var sortLabel = '';

	switch (settings.currentView) {
		case "Flows":
			var menuItems     = sortFlowsMenuItems;
			var sortColumn    = settings.sortFlows.split(' ')[0];
			var sortDirection = settings.sortFlows.split(' ')[1];
			break;
		case "Jobs":
			var menuItems     = sortJobsMenuItems;
			var sortColumn    = settings.sortJobs.split(' ')[0];
			var sortDirection = settings.sortJobs.split(' ')[1];
			break;
		case "Steps":
			var menuItems     = [];
			var sortColumn    = '';
			var sortDirection = '';
			break;
		default:
	}

	for (i=0; i < menuItems.length; i++) {
		if (menuItems[i].value == sortColumn) {
			sortLabel = menuItems[i].text;
		}
	}

	$("#menubuttonSort").button({ icons: { secondary: ( sortDirection == 'asc' ? "ui-icon-arrowthick-1-s" : "ui-icon-arrowthick-1-n" ) }
								, label: 'Sort: ' + sortLabel
								})

}//updateSortButtonLabel


function createFilterMenu() {

  var filterMenuItems = [];
  var currentFilter = '';
  switch (settings.currentView) {

	case "Flows" :
	  filterMenuItems = filterFlowsMenuItems;
	  currentFilter   = settings.filterFlows;
	  break;

	case "Jobs"  :
	  filterMenuItems = filterJobsMenuItems;
	  currentFilter   = settings.filterJobs;
	  break;

	default:
	  filterMenuItems    = [];
	  currentFilter = '';
  }

  var s = '';
  s += '<ul class="dropdown-menu">';

  // Add Filter items
  for (i=0; i < filterMenuItems.length; i++) {
	s += '<li class="li-dropdown-item li-dropdown-filter-item ui-widget" id="filter-' + filterMenuItems[i].value + '"><div>'
	   + '<span class="ui-icon ui-icon-dropdown-item ' + (currentFilter == filterMenuItems[i].value ? 'ui-icon-check' : 'ui-icon-blank' ) + '"></span>'
	   + '<span class="text-dropdown-item">' + filterMenuItems[i].text + '</span>'
	   + '</div><br></li>'
	   ;
  }

  s += '</ul>';

  var menuWidth      = 193;
  button = $("#menubuttonFilter");
  var buttonPosition = button.position();
  var buttonLeft     = buttonPosition.left;
  var buttonBottom   = buttonPosition.top + button.height() + 6;
  var menuLeft       = buttonLeft + button.width() - menuWidth;
  $("#menuFilter").remove(); // remove menu in case it already exists
  var menuFilter = $('<div id="menuFilter" style="display:block;'
												+'position:absolute;'
												+'top:' + buttonBottom + 'px;'
												+'left:' + menuLeft + 'px;'
												+'width:' + menuWidth + 'px;'
												+'z-index:1001;'
												+'" class="dropdown-menu"></div>').appendTo('body');
  $("#menuFilter").html(s);
  $('.li-dropdown-filter-item').click( function () { filter($(this).attr('id').split('-')[1]); });

}//createFilterMenu


function filter(options) {

  switch (settings.currentView) {
	case "Flows" :
		settings.filterFlows = options;
		Cookies.set('dimonFilterFlows',options,{ expires: 365 });
		break;
	case "Jobs"  :
		settings.filterJobs = options;
		Cookies.set('dimonFilterJobs',options,{ expires: 365 });
		break;
	default:
  }
	setTimeout(function() {
		updateFilterButtonLabel();
		$("#menuFilter").remove();
	},500);
	refresh();

}//filter


function createSortMenu() {

	var SortMenuItems = [];
	var currentSort = '';
	switch (settings.currentView) {

	case "Flows" :
		sortMenuItems     = sortFlowsMenuItems;
		var sortColumn    = ( settings.sortFlows.split(' ')[0] == null ? 'trigger_time' : settings.sortFlows.split(' ')[0] );
		var sortDirection = ( settings.sortFlows.split(' ')[1] == null ? 'desc'         : settings.sortFlows.split(' ')[1] );
		break;

	case "Jobs"  :
		sortMenuItems    = sortJobsMenuItems;
		var sortColumn    = ( settings.sortJobs.split(' ')[0] == null ? 'trigger_time' : settings.sortJobs.split(' ')[0] );
		var sortDirection = ( settings.sortJobs.split(' ')[1] == null ? 'desc'         : settings.sortJobs.split(' ')[1] );
		break;

	default:
		sortMenuItems    = [];
		currentSort = '';
	}

  var s = '';
  s += '<ul class="dropdown-menu">';

  // Add Sort items
  for (i=0; i < sortMenuItems.length; i++) {
	s += '<li class="li-dropdown-item li-dropdown-sort-item ui-widget" id="sort-' + sortMenuItems[i].value + '"><div>'
	   +   '<span class="ui-icon ui-icon-dropdown-item ' + ( sortColumn == sortMenuItems[i].value ? 'ui-icon-check' : 'ui-icon-blank' ) + '"></span>'
	   +   '<span class="text-dropdown-item">' + sortMenuItems[i].text + '</span>';
	if (sortColumn == sortMenuItems[i].value) {
		s += '<span class="ui-icon ui-icon-dropdown-item sortmenu-sort-direction-item ' + ( sortDirection == 'asc' ? "ui-icon-arrowthick-1-s" : "ui-icon-arrowthick-1-n" ) + '"></span>'
	}
	s += '</div><br></li>';
  }

  s += '</ul>';
  menuWidth = 300;
  button = $("#menubuttonSort");
  var buttonPosition = button.position();
  var menuLeft       = buttonPosition.left;
  var menuTop        = buttonPosition.top + button.height() + 6;
  $("#menuSort").remove(); // remove menu in case it already exists
  var menuSort = $('<div id="menuSort" style="display:block;'
											+'position:absolute;'
											+'top:' + menuTop + 'px;'
											+'left:' + menuLeft + 'px;'
											+'width:' + menuWidth + 'px;'
											+'z-index:1001;'
											+'" class="dropdown-menu"></div>').appendTo('body');
  $("#menuSort").html(s);
  $('.li-dropdown-sort-item').click( function () { sort($(this).attr('id').split('-')[1]); });

}//createSortMenu


function sort(sortColumn) {

	var currentSortColumn = '';
	var currentSortOrder  = '';

	switch (settings.currentView) {

		case "Flows":
			currentSortColumn = settings.sortFlows.split(' ')[0];
			currentSortOrder  = settings.sortFlows.split(' ')[1];
			break;

		case "Jobs":
			currentSortColumn = settings.sortJobs.split(' ')[0];
			currentSortOrder  = settings.sortJobs.split(' ')[1];
			break;

		default:

	}

	if (sortColumn == currentSortColumn) {
		sortOrder = (currentSortOrder == 'asc' ? 'desc' : 'asc' );// reverse sort order
	} else {
		var sortOrder = 'asc';// default sort order is ascending
	}

	switch (settings.currentView) {

		case "Flows":
			settings.sortFlows = sortColumn + ' ' + sortOrder;
			Cookies.set('dimonSortFlows',settings.sortFlows,{ expires: 365 });
			break;

		case "Jobs":
			settings.sortJobs  = sortColumn + ' ' + sortOrder;
			Cookies.set('dimonSortJobs',settings.sortJobs,{ expires: 365 });
			break;

		default:

	}

	$("#menuSort").remove();
	createSortMenu();
	setTimeout(function() {
		$("#menuSort").remove();
		updateSortButtonLabel();
	},500);
	refresh();

}//sort


function getSPName(spname) {
  return settings.sproot + "/" + spname;
}//getSPName


function navigate(path) {

	settings.currentPath = path; // save for refresh
	switch(path.split('_')[0]) {

		case "//":
			Flows(path.split('_')[1]);  // run_date
			break;

		case "flow":
			Jobs(path);
			break;

		case "job":
			Steps(path);
			break;

		default:

	}

}//navigate


function refresh() {

	navigate(settings.currentPath);

}//refresh


function menuNavbar() {

	$('#menuNavbar').remove(); // remove filter in case it already exists

	var s =   '<ul class="dropdown-menu">'
			+  '<li class="li-dropdown-item" id="copyPath">'
			+   '<div><span class="text-dropdown-item  ui-widget">&nbsp;&nbsp;Navigation path</span></div><br>'
			+  '</li>'
			+ '</ul>';
	button = $("#menubuttonNavbar");
	var menuWidth = 240;
	var buttonPosition = button.position();
	var menuLeft       = buttonPosition.left + button.width() - menuWidth;
	var menuTop        = buttonPosition.top + button.height() + 8;
	$("#menuNavbar").remove(); // remove menu in case it already exists
	var menuNavbar = $('<div id="menuNavbar" style="display:block;position:absolute;top:' + menuTop + 'px;left:' + menuLeft + 'px;width:' + menuWidth + 'px;z-index:1001;" class="dropdown-menu"></div>').appendTo('body');
	$("#menuNavbar").html(s);
	$("#copyPath").click( function () {
		$("#menuNavbar").remove();
		dialogNavigationPath();
	});
	$("#menuNavbar").show();
	
}//menuNavbar


function dialogNavigationPath() {

  var dialogWidth  = $(window).width()*0.6;
  var dialogHeight = 175;
  var dialog = $( '<div id="dialogNavigationPath">'
				+ '<p>'
				+ '<input type="text" id="navigationPath">'
				+ '</p>'
				+ '</div>').appendTo('body');
  dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					 close : function(event, ui) {
							   // remove div with all data and events
							   dialog.remove();
							 }
				,    title : 'Navigation Path'
				,    width : dialogWidth
				,   height : dialogHeight
				,    modal : true
				,  buttons : { "Copy to clipboard"	:	function(event, ui) {
															$("#navigationPath").select();
															document.execCommand("copy");
														}
							 , "Close"	:	function(event, ui) {
												$(this).dialog('close');
											}
							}
				});

	var url = $(location).attr('protocol')+'//'+$(location).attr('host')+settings.webroot+'/?path='+$('#navpath .navpath-item:last').attr('id');
	$("#navigationPath").css("width",dialogWidth-55).css("text-align","left").button().val(url);
	
}//dialogNavigationPath


function Flows(run_date) {

	clearInterval(interval);
	settings.currentView = 'Flows';
	updateFilterButtonLabel();
	updateSortButtonLabel();
	$("#menubuttonFilter").button("enable");
	$("#menubuttonSort").button("enable");
	$("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');	
	refreshFlows(run_date);
	if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
		interval = setInterval("refreshFlows('" + run_date + "')",autorefresh_intervals[settings.autorefresh_interval]*1000);
	}

}//Flows


function refreshFlows(run_date) {

  if ($("#results1").length) {

	$.ajax({     url : settings.urlSPA
		   ,    data : $.extend({}
							   ,{  "_program" : getSPName('dimonFlows')
								,  "run_date" : run_date
								,    "filter" : settings.filterFlows
								,      "sort" : settings.sortFlows
								,    "search" : $('#search').val()
								,    "_debug" : _debug
								})
		   ,   cache : false
		   , success : function(data) {

						 // To prevent delayed output from SP, check if we're still in Flows view.
						 if (settings.currentView == 'Flows') {

							$("#results1").html(data);

							// move SAS-generated report title to #dimon-navbar
							$("#dimon-navbar").html('<div id="navpath"></div><span id="menubuttonNavbar"></span>');
							$("#menubuttonNavbar").html(svgMenuNavbar).button().click(function() {
								menuNavbar();
							});
							$("#results1 .systitleandfootercontainer").appendTo("#navpath");
							$("#results1").find('br:first').remove();

							// move SAS-generated footer to #dimon-footer
							$("#dimon-footer").html("");
							$("#results1 .reportfooter").appendTo("#dimon-footer");

							$("#datepicker").datepicker({ dateFormat : "ddMyy"
														, showButtonPanel: true
														,   onSelect : function(date) {
																		navigate('//_' + $.datepicker.formatDate('ddMyy',$("#datepicker").datepicker("getDate")));
														}})
											.datepicker("setDate",run_date);
							 
						    $(".navpath-item").button()
												.click(function() {
													$("#datepicker").datepicker('show');
												});

							$(".flow-status-link").click(function() {
								viewNotesWarningsErrors({     "flow_run_id" : $(this).attr('id').split('_')[1]
														, "flow_run_seq_nr" : $(this).attr('id').split('_')[2]
														,              "rc" : $(this).attr('id').split('_')[3]
														});
						   });
							$(".flow-drilldown-link").click(function() {
								navigate($(this).attr('id'));
							});
						   $(".start-dts-link").click(function() {
							 plot({	     "flow_run_id" : $(this).attr('id').split('_')[1]
									,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
									,    "flow_job_id" : $(this).attr('id').split('_')[3]
									,      "plot_yvar" : "START_END_TIME"
									});
						   });
						   $(".end-dts-link").click(function() {
							 plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
										 ,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
										 ,    "flow_job_id" : $(this).attr('id').split('_')[3]
										 ,      "plot_yvar" : "END_TIME"
							             });
						   });
						   $(".elapsed-time-link").click(function() {
							 plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
										 ,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
										 ,    "flow_job_id" : $(this).attr('id').split('_')[3]
										 ,      "plot_yvar" : "ELAPSED_TIME"
							             });
						   });
						   $(".realtime-flows-audit-stats-link").click(function() {
							 realtimeFlowAuditStats($(this).attr('id').split('_')[1]);
						   });
						   $(".dimon-status-progressbar").progressbar()
														 .each(function(i) {
															var value = parseInt(this.id.split('_')[1]); // get value from id
											                if (isNaN(value)) {
																$(this).progressbar( "option", "value", false ); // no value found -> undeterminate
															} else {
																var progressbarValue = Math.min(100,Math.max(5,value)); //value  min=5%, max=100%
																$(this).progressbar("value",progressbarValue);
											                    $(this).find('span').text(value + "%");
															}
															$(this).removeClass('ui-corner-all');
														  });
						   $(".trend-sparkline").each(function() {
							 $(this).sparkline('html',{width:'150px',fillColor:undefined})
							        .click(function(e) { plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
																	 ,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
										                             ,    "flow_job_id" : $(this).attr('id').split('_')[3]
										                             ,      "plot_yvar" : "ELAPSED_TIME"
							                                         });
														});

						   });

						   //$(".dimon-bar").addClass('ui-corner-all'); // give gantt bars rounded corners
						   $(":button:contains('Filter')").button("enable");
						   
						   setResults1Size();
						   setSearchSize();

						 }
					   }
		   ,   error : function(XMLHttpRequest,textStatus,errorThrown) {
						 var r= confirm('dimonFlows'
									  + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									  + '\n\nClick OK to view the SAS log, Cancel to quit.');
						 if (r == true) {
						   showSasError(XMLHttpRequest.responseText);
						 }
					   }
	});
  }

}//refreshFlows


function Jobs(path) {

	clearInterval(interval);
	settings.currentView = 'Jobs';
	updateFilterButtonLabel();
	updateSortButtonLabel();
	$("#menubuttonFilter").button("enable");
	$("#menubuttonSort").button("enable");
	$("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
	refreshJobs(path);
	if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
		interval = setInterval('refreshJobs("' + path + '")',autorefresh_intervals[settings.autorefresh_interval]*1000);
	}

}//Jobs


function refreshJobs(path) {

  if ($("#results1").length) {

	$.ajax( {     url : settings.urlSPA
			,    data : {        "_program" : getSPName('dimonJobs')
						,     "flow_run_id" : path.split('_')[1]
						, "flow_run_seq_nr" : path.split('_')[2]
						,     "flow_job_id" : path.split('_')[3]
						,        "run_date" : path.split('_')[4]
						,          "filter" : settings.filterJobs
						,            "sort" : settings.sortJobs
						,          "search" : $('#search').val()
						,          "_debug" : _debug
						}
			,   cache : false
			, success : function(data) {

							// To prevent delayed output from SP, check if we're still in Jobs view.
							if (settings.currentView == 'Jobs') {
								
								$("#results1").html(data);
							
								// move SAS-generated report title to #dimon-navbar
								$("#dimon-navbar").html('<div id="navpath"></div><span id="menubuttonNavbar"></span>');
								$("#menubuttonNavbar").html(svgMenuNavbar).button().click(function() {
									menuNavbar();
								});
								$("#results1 .systitleandfootercontainer").appendTo("#navpath");
								$("#results1").find('br:first').remove();

								// move SAS-generated footer to #dimon-footer
								$("#dimon-footer").html("");
								$("#results1 .reportfooter").appendTo("#dimon-footer");
								
								$(".navpath-item").button().click(function() { navigate($(this).attr('id')); });

								$(".flow-status-link").click(function() {
									viewNotesWarningsErrors({     "flow_run_id" : $(this).attr('id').split('_')[1]
															, "flow_run_seq_nr" : $(this).attr('id').split('_')[2]
															,              "rc" : $(this).attr('id').split('_')[3]
															,     "flow_job_id" : $(this).attr('id').split('_')[4]
															});
								});
								$(".job-status-link").click(function() {
									viewNotesWarningsErrors({"job_run_id" : $(this).attr('id').split('_')[1]
															,        "rc" : $(this).attr('id').split('_')[2]
															});
								});
								$(".flow-drilldown-link").click(function() {
									navigate($(this).attr('id'));
								});
								$(".job-drilldown-link").click(function() {
									navigate($(this).attr('id'));
								});
								$(".start-dts-link").click(function() {
								plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
											,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
											,    "flow_job_id" : $(this).attr('id').split('_')[3]
											,      "plot_yvar" : "START_END_TIME"
											});
								});
								$(".end-dts-link").click(function() {
								plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
											,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
											,    "flow_job_id" : $(this).attr('id').split('_')[3]
											,      "plot_yvar" : "END_TIME"
											});
								});
								$(".elapsed-time-link").click(function() {
								plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
											,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
											,    "flow_job_id" : $(this).attr('id').split('_')[3]
											,      "plot_yvar" : "ELAPSED_TIME"
											});
								});
								$(".view-log-link").click(function() { viewLog($(this).attr('id').split('_')[1]); });
								$(".dimon-status-progressbar").progressbar()
																.each(function(i) {
																var value = parseInt(this.id.split('_')[1]); // get value from id
																if (isNaN(value)) {
																	$(this).progressbar( "option", "value", false ); // no value found -> undeterminate
																} else {
																	var progressbarValue = Math.min(100,Math.max(5,value)); //value  min=5%, max=100%
																	$(this).progressbar("value",progressbarValue);
																$(this).find('span').text(value + "%");
																}
																$(this).removeClass('ui-corner-all');
																});
								$(".trend-sparkline").each(function() {
								$(this).sparkline('html',{width:'150px',fillColor:undefined})
										.click(function(e) { plot({    "flow_run_id" : $(this).attr('id').split('_')[1]
																	,"flow_run_seq_nr" : $(this).attr('id').split('_')[2]
																	,    "flow_job_id" : $(this).attr('id').split('_')[3]
																	,      "plot_yvar" : "ELAPSED_TIME"
																	});
															});

								setResults1Size();

						   });
						   $(":button:contains('Filter')").button("enable");
						 }
					   }
		   ,   error : function(XMLHttpRequest,textStatus,errorThrown) {
						 var r= confirm("dimonJobs"
									  + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									  + '\n\nClick OK to view the SAS log, Cancel to quit.');
						 if (r == true) {
						   showSasError(XMLHttpRequest.responseText);
						 }
					   }
	});
  }

}//refreshJobs


function Steps(path) {

	clearInterval(interval);
	settings.currentView = 'Steps';
	updateFilterButtonLabel();
	updateSortButtonLabel();
	$("#menubuttonFilter").button("disable");
	$("#menubuttonSort").button("disable");
	$("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
	refreshSteps(path);
	if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
		interval = setInterval('refreshSteps("' + path + '")',autorefresh_intervals[settings.autorefresh_interval]*1000);
	}

}//Steps


function refreshSteps(path) {

  if ($("#results1").length) {
	$.ajax({     url : settings.urlSPA
		   ,    data :	{   "_program" : getSPName('dimonSteps')
						, "job_run_id" : path.split('_')[1]
						,     "_debug" : _debug
						}
		   ,   cache : false
		   , success : function(data) {

							// To prevent delayed output from SP, check if we're still in Steps view.
							if (settings.currentView == 'Steps') {

								$("#results1").html(data);

								// move SAS-generated report title to #dimon-navbar
								$("#dimon-navbar").html('<div id="navpath"></div><span id="menubuttonNavbar"></span>');
								$("#menubuttonNavbar").html(svgMenuNavbar).button().click(function() {
									menuNavbar();
								});
								$("#results1 .systitleandfootercontainer").appendTo("#navpath");
								$("#results1").find('br:first').remove();

								// move SAS-generated footer to #dimon-footer
								$("#dimon-footer").html("");
								$("#results1 .reportfooter").appendTo("#dimon-footer");

								$(".navpath-item").button().click(function() { navigate($(this).attr('id')); });
								$(".view-log-link").click(function() {
									viewLog($(this).attr('id').split('_')[1]
										,$(this).attr('id').split('_')[2]);
									});

								$(":button:contains('Filter')").button("disable");
								$(".dimon-info-message").addClass('ui-state-highlight');
								$(".dimon-error-message").addClass('ui-state-error');

								setResults1Size();

							}
					   }
		   ,   error : function(XMLHttpRequest,textStatus,errorThrown) {
						 var r= confirm("dimonSteps"
									  + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									  + '\n\nClick OK to view the SAS log, Cancel to quit.');
						 if (r == true) {
						   showSasError(XMLHttpRequest.responseText);
						 }
					   }
	});
  }

}//refreshSteps


function viewLog(job_run_id,anchor) {

  // get logfile filesize
  $.ajax({     type : "GET"
		 ,      url : settings.urlSPA
		 ,     data :	{   "_program" : getSPName('dimonGetLogfileSize')
						, "job_run_id" : job_run_id
						,     "_debug" : _debug
						}
		 , dataType : 'json'
		 ,    async : true
		 ,    cache : false
		 ,  timeout : 60000 /* in ms */
		 ,  success : function(data) {

						// chrome and firefox can handle much larger files than ie so maxsize is doubled for them
						if (data.filesize > settings.viewlog_maxfilesize) {
						  var dialog = $('<div id="dialog-confirm" title="View SAS log file">'
									   + '<p><span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 20px 0;"></span>'
									   + 'The log file is large (' + data.filesize + ' bytes) and could take a long time'
									   + ' and a large amount of system resources to display in DI Monitor.'
									   + '<br>How do you want to view the file?</p>'
									   ).appendTo('body');
						  dialog.dialog({
							  // add a close listener to prevent adding multiple divs to the document
							  close : function(event, ui) {
								  // remove div with all data and events
								  dialog.remove();
							  },
							  resizable: false,
							  width: 400,
							  modal: true,
							  buttons: {
								  "View in DI Monitor": function() {
									$(this).dialog("close");
									viewLogInDimon(job_run_id,anchor);
								  }
							  ,   "View in external viewer": function() {
									  $(this).dialog("close");
									  window.location.href = settings.urlSPA + '?_program=' + getSPName('dimonViewLogExternally') + '&job_run_id=' + job_run_id;
								  }
							  ,   Cancel: function() {
									  $(this).dialog("close");
								  }
							  }
						  });
						  $(":button:contains('external')").focus(); // Set focus to the [View in external viewer] button
						} else {
						  viewLogInDimon(job_run_id,anchor);
						}
					  }
		 ,    error : function(XMLHttpRequest,textStatus,errorThrown) {
						var r= confirm("dimonGetLogfileSize"
									 + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									 + '\n\nClick OK to view the SAS log, Cancel to quit.');
						if (r == true) {
						  showSasError(XMLHttpRequest.responseText);
						}
					  }
  });

}//viewLog


function viewLogInDimon(job_run_id,anchor) {

  dialog = $('<div id="dialogViewLog" style="display:none">'
		   +   '<div id="viewlogHeader">'
		   +     '<div id="viewlogTitle" class="l systemtitle SystemTitle"></div>'
		   +   '</div>'
		   +   '<div id="viewlogContent"></div>'
		   + '</div>').appendTo('body');
  dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					 close : function(event, ui) {
							   // remove div with all data and events
							   dialog.remove();
							 }
				,    title : 'SAS Log for Job Run ID ' + job_run_id
				,    width : $(window).width()*0.95
				,   height : $(window).height()*0.95
				,    modal : true
				,   resize : function(event,ui) {
								setViewLogContentSize();
							 }
				,  buttons : { "Reload" : function(event,ui) {
											$(":button:contains('Reload')").button("disable");
											getLog(job_run_id,'max');
										  }
							 , "Close" : function(event,ui) {
										   $(this).dialog('close');
										 }
							 }
				});
  if (anchor == undefined) {
	anchor = ( $('#viewlogCheckboxAutoRefresh').is(':checked') ? 'max' : 'l1' );
  }
  getLog(job_run_id,anchor);

}//viewLogInDimon


function getLog(job_run_id,anchor) {

  $.ajax({     type : "GET"
		 ,      url : settings.urlSPA
		 ,     data :	{   "_program" : getSPName('dimonGetLogfileName')
						, "job_run_id" : job_run_id
						,     "_debug" : _debug
						}
		 ,    async : true
		 ,    cache : false
		 , dataType : 'json'
		 ,  timeout : 60000 /* in ms */
		 ,  success : function(data) {
					$("#viewlogTitle").html("File: " + data.job_log_file);
				  }
		 ,    error : function(XMLHttpRequest,textStatus,errorThrown) {
						var r= confirm("dimonGetLogfileName"
									 + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									 + '\n\nClick OK to view the SAS log, Cancel to quit.');
						if (r == true) {
						  showSasError(XMLHttpRequest.responseText);
						}
					  }
  });

  $("#viewlogContent").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
  $.ajax({     type : "GET"
		,      url : settings.urlSPA
		,     data :	{   "_program" : getSPName('dimonViewLog')
						, "job_run_id" : job_run_id
						,     "_debug" : _debug
						}
		,    async : true
		,    cache : false
		,  timeout : 60000 /* in ms */
		,  success : function(data) {
						$("#viewlogContent").html(data);
						$("#viewlogContent").focus();// IE7 Standard document mode hack to fix scrolling with absolute div positioning
						$("#viewlogContent").scrollTo(anchor
												,300 /* scroll animation time */
												,{offset:-15}
												);
						$(":button:contains('Reload')").button("enable");
						$(":button:contains('Close')").focus(); // Set focus to the [Close] button
						$(".dimon-info-message").addClass('ui-state-highlight');
						$(".dimon-error-message").addClass('ui-state-error');						
						setViewLogContentSize();
					}
		,    error : function(XMLHttpRequest,textStatus,errorThrown) {
						var r= confirm("dimonViewLog"
										+ '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
										+ '\n\nClick OK to view the SAS log, Cancel to quit.');
						if (r == true) {
							showSasError(XMLHttpRequest.responseText);
						}
					}
  });

}//getLog


function plot(parms) {

	parms.div = "plot";
	var plot_histdays     = ( Cookies.get('dimonPlotHistDays')     == null ?    90 : Cookies.get('dimonPlotHistDays')     );
	var plot_ci           = ( Cookies.get('dimonPlotCI')           == null ?    95 : Cookies.get('dimonPlotCI')           );
	var plot_showzero     = ( Cookies.get('dimonPlotShowZero')     == null ? 'yes' : Cookies.get('dimonPlotShowZero')     );
	//var plot_hideoutliers = ( Cookies.get('dimonPlotHideOutliers') == null ?  'no' : Cookies.get('dimonPlotHideOutliers') );
	var plot_hideoutliers = 'no';

	var dialog	= $('<div id="dialogHistoryPlot" style="display:none">'
				+  '<div id="plotControls" class="ui-widget">'
				+  '<form action="#">'
				+    '<fieldset>'
				+      '<label for="combobox-numdays">Number of days</label>'
				+      '<select name="combobox-numdays" id="combobox-numdays" class="dimon-combobox">'
				+        '<option value="1"'   + (plot_histdays ==   '1' ? ' selected="selected"' : '' ) + '>1 day</option>'
				+        '<option value="7"'   + (plot_histdays ==   '7' ? ' selected="selected"' : '' ) + '>7 days</option>'
				+        '<option value="14"'  + (plot_histdays ==  '14' ? ' selected="selected"' : '' ) + '>14 days</option>'
				+        '<option value="30"'  + (plot_histdays ==  '30' ? ' selected="selected"' : '' ) + '>30 days</option>'
				+        '<option value="60"'  + (plot_histdays ==  '60' ? ' selected="selected"' : '' ) + '>60 days</option>'
				+        '<option value="90"'  + (plot_histdays ==  '90' ? ' selected="selected"' : '' ) + '>90 days</option>'
				+        '<option value="180"' + (plot_histdays == '180' ? ' selected="selected"' : '' ) + '>180 days</option>'
				+        '<option value="360"' + (plot_histdays == '360' ? ' selected="selected"' : '' ) + '>360 days</option>'
				+        '<option value="720"' + (plot_histdays == '720' ? ' selected="selected"' : '' ) + '>720 days</option>'
				+      '</select>'
				+      '<label for="combobox-ci">Confidence interval</label>'
				+      '<select name="combobox-ci" id="combobox-ci" class="dimon-combobox">'
				+        '<option value="90"'  + (plot_ci ==  '90' ? ' selected="selected"' : '' ) + '>90%</option>'
				+        '<option value="95"'  + (plot_ci ==  '95' ? ' selected="selected"' : '' ) + '>95%</option>'
				+        '<option value="99"'  + (plot_ci ==  '99' ? ' selected="selected"' : '' ) + '>99%</option>'
				+      '</select>'
				+      '<label for="checkbox-showzero">Show zero on vertical axis</label>'
				+      '<input id="checkbox-showzero" class="dimon-checkbox showzero" type="checkbox"' + ( plot_showzero == 'yes' ? ' checked="checked"' : '' ) + '>'
				+      '<label for="checkbox-hideoutliers">Hide outliers</label>'
				+      '<input id="checkbox-hideoutliers" class="dimon-checkbox hideoutliers" type="checkbox"' + ( plot_hideoutliers == 'yes' ? ' checked="checked"' : '' ) + '>'
				+    '<fieldset>'
				+  '</div>'
				+  '<div id="plot">'
				+    '<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />'
				+  '</div>'
				+'</div>').appendTo('body');
	dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					close : function(event, ui) {
								// remove div with all data and events
								dialog.remove();
							}
				,    title : 'Elapsed Time History'
				,    width : 1250
				,   height : 640
				,    modal : true
				,  buttons : { "Close" : function(event, ui) {
											$(this).dialog('close');
										}
							}
				});
  $(".dimon-combobox").selectmenu({
		 change: function(event,data) {
			Cookies.set('dimonPlotHistDays',$("#combobox-numdays").val(),{ expires: 365 });
			Cookies.set('dimonPlotCI',$("#combobox-ci").val(),{ expires: 365 });
			createPlot(parms); }
	   });
  $("#checkbox-showzero").button()
						 .click(function() {
							Cookies.set('dimonPlotShowZero',( $("#checkbox-showzero").is(':checked') ? "yes" : "no" ),{ expires: 365 });
							createPlot(parms);
							});
  $("#checkbox-hideoutliers").button()
							 .click(function() {
							 	Cookies.set('dimonPlotHideOutliers',( $("#checkbox-hideoutliers").is(':checked') ? "yes" : "no" ),{ expires: 365 });
								createPlot(parms);
								});

  // load remote content
  createPlot(parms);
  $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//historyPlot


function createPlot(parms) {

  $('#' + parms.div).html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
  $.ajax(	{     type : "GET"
			,      url : settings.urlSPA
			,     data : $.extend({           "_program" : getSPName("dimonPlot")
									,     "plot_histdays" : $("#combobox-numdays").val()
									,           "plot_ci" : $("#combobox-ci").val()
									,     "plot_showzero" : ( $("#checkbox-showzero").is(':checked') ? "yes" : "no" )
									, "plot_hideoutliers" : ( $("#checkbox-hideoutliers").is(':checked') ? "yes" : "no" )
									,      "plot_xpixels" : "900"
									,      "plot_ypixels" : "400"
									,      "_gopt_device" : 'png'
									,            "_debug" : _debug
									}
									,parms)
			,    cache : false
			,  success : function(data) {
						$('#' + parms.div).html(data);
						}
			,    error : function(XMLHttpRequest,textStatus,errorThrown) {
							var r= confirm("dimonPlot"
											+ '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
											+ '\n\nClick OK to view the SAS log, Cancel to quit.');
							if (r == true) {
								showSasError(XMLHttpRequest.responseText);
							}
						}
		});

}//createHistoryPlot


function viewNotesWarningsErrors(parms) {

  var dialog = $('<div id="dialogNotesWarningsErrors" style="display:none"></div>').appendTo('body');
  var s = '';
  s += '<div id="menubarNotesWarningsErrors">';
  s += '<div id="titleNotesWarningsErrors" class="l systemtitle SystemTitle"><span>Notes, Warnings and/or Errors for '
	   + ( parms.flow_run_id !== undefined ?   'Flow Run ID ' + parms.flow_run_id + ' / ' + parms.flow_run_seq_nr
											 : 'Job Run ID '  + parms.job_run_id )
	   + '</span></div>'
	   ;
  var rc = 2;
  if (parms.rc !== undefined) {
	rc = parms.rc;
  }
  s +=   '<div id="buttonbarNotesWarningsErrors">';
  s +=     '<input type="checkbox" id="flowDetailsNotes" '    + ( rc == 0 ? 'checked="checked"' : "" ) + ' /><label for="flowDetailsNotes">Notes</label>';
  s +=     '<input type="checkbox" id="flowDetailsWarnings" ' + ( rc == 1 ? 'checked="checked"' : "" ) + ' /><label for="flowDetailsWarnings">Warnings</label>';
  s +=     '<input type="checkbox" id="flowDetailsErrors" '   + ( rc >= 2 ? 'checked="checked"' : "" ) + ' /><label for="flowDetailsErrors">Errors</label>';
  s +=   '</div>';
  s += '</div>';
  s += '<div id="sasresultNotesWarningsErrors"></div>';
  $("#dialogNotesWarningsErrors").html(s);
  $("div#buttonbarNotesWarningsErrors").buttonset();
  $("div#buttonbarNotesWarningsErrors :checkbox").click(function(e) {
	loadNotesWarningsErrorsContent(dialog,parms);
  });
  dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					close : function(event, ui) {
							// remove div with all data and events
							dialog.remove();
							}
				,    title : 'Notes, Warnings, Errors'
				,    width : $(window).width()*0.95
				,   height : $(window).height()*0.95
				,    modal : true
				,  buttons : { "Close" : function(event, ui) {
										$(this).dialog('close');
										}
							}
				});

  loadNotesWarningsErrorsContent(dialog,parms);
  $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//viewNotesWarningsErrors


function loadNotesWarningsErrorsContent(dialog,parms) {

  // load remote content flowDetails
  $("#sasresultNotesWarningsErrors").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
  $.ajax({     type : "GET"
		 ,      url : settings.urlSPA
		 ,     data : $.extend({      "_program" : getSPName('dimonViewNotesWarningsErrors')
								,    "showNotes" : ( $('#flowDetailsNotes').is(':checked')    ? "Y" : "N" )
								, "showWarnings" : ( $('#flowDetailsWarnings').is(':checked') ? "Y" : "N" )
								,   "showErrors" : ( $('#flowDetailsErrors').is(':checked')   ? "Y" : "N" )
								,       "_debug" : _debug
								}
								,parms)
		 ,    async : true
		 ,    cache : false
		 ,  timeout : 60000 /* in ms */
		 ,  success : function(data) {
						$("#sasresultNotesWarningsErrors").html(data);
						$(".view-log-links").click( function() { viewLog($(this).attr('id').split('_')[1]
																		,$(this).attr('id').split('_')[2]);
																});
						$(":button:contains('Close')").focus(); // Set focus to the [Close] button
						$(".dimon-info-message").addClass('ui-state-highlight');
					  }
		 ,    error : function(XMLHttpRequest,textStatus,errorThrown) {
						var r= confirm("dimonViewNotesWarningsErrors"
									 + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
									 + '\n\nClick OK to view the SAS log, Cancel to quit.');
						if (r == true) {
						  showSasError(XMLHttpRequest.responseText);
						}
					  }
  });

}//loadNotesWarningsErrorsContent


function showSasError(msg) {

  var dialog = $('<div id="dialogSasError"></div>').appendTo("body");
  dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
					 close : function(event, ui) {
							   // remove div with all data and events
							   dialog.remove();
							 }
				,    title : 'SAS Error'
				,    width : $(window).width()*0.75
				,   height : $(window).height()*0.95
				,    modal : true
				,  buttons : { "Close" : function(event, ui) {
										   $(this).dialog('close');
										 }
							 }
				});
  $("#dialogSasError").html(msg);
  $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//showSasError


// This function is for the Stored Processes Show SAS Log and Hide SAS Log functionality
// which for some reason doesn't work with div's, so we copy-and-pasted it to here
var SASLOGisVisible = false;
function toggleLOG() {
  container = document.getElementById("SASLOGContainer");
  content   = document.getElementById("SASLOG");
  button    = document.getElementById("LOGbutton");
  if (SASLOGisVisible === false) {
	container.innerHTML = content.innerHTML;
	button.value="Hide SAS Log";
	SASLOGisVisible = true;
  } else {
	container.innerHTML = "";
	button.value="Show SAS Log";
	SASLOGisVisible = false;
	// Added for DIMon - START
	clearInterval(interval);
   // Added for DIMon - END
  }
}//toggleLOG


var getUrlParameter = function getUrlParameter(sParam) {
	var sPageURL = decodeURIComponent(window.location.search.substring(1)),
		sURLVariables = sPageURL.split('&'),
		sParameterName,
		i;

	for (i = 0; i < sURLVariables.length; i++) {
		sParameterName = sURLVariables[i].split('=');

		if (sParameterName[0] === sParam) {
			return sParameterName[1] === undefined ? true : sParameterName[1];
		}
	}
}//getUrlParameterer