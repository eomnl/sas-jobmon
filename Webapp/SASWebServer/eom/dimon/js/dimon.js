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

var settings = {
    urlSPA: ''
    , sproot: ''
    , imgroot: ''
    , _gopt_device: ''
    , _odsstyle: ''
    , currentView: ''
    , flowsmode: ''
    , currentViewParms: ''
    , currentPath: ''
    , autorefresh_interval: 5
    , filterFlows: 'all_flows_excl_hidden'
    , filterJobs: 'all_jobs'
    , sortFlows: ''
    , sortJobs: ''
    // , rundateHistDays: 0
};

var _debug;
var interval = 0; // for javascript setInterval function
var refreshFlowsRunning = false;
var refreshJobsRunning = false;
var refreshStepsRunning = false;
var ajaxTimeout = 60000; // timeout value for Ajax calls
var ajaxTimedOut = false;
var autorefresh_intervals = [1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 90, 105, 120, 180, 240, 300, 600, 900, 1200, 1500, 1800, 2700, 3600, 7200, 9999999];
var svgDotsVertical = '<svg style="width:20px;height:20px" viewBox="0 0 24 24">'
    + '<path fill="#454545" d="M12,16A2,2 0 0,1 14,18A2,2 0 0,1 12,20A2,2 0 0,1 10'
    + ',18A2,2 0 0,1 12,16M12,10A2,2 0 0,1 14,12A2,2 0 0,1 12,14A2,2 0 0,1 10,12A2'
    + ',2 0 0,1 12,10M12,4A2,2 0 0,1 14,6A2,2 0 0,1 12,8A2,2 0 0,1 10,6A2,2 0 0,1 12,4Z" />'
    + '</svg>';

var filterFlowsMenuItems = [{ 'value': 'running', 'text': 'Running' }
    , { 'value': 'completed', 'text': 'Completed' }
    , { 'value': 'failed', 'text': 'Failed' }
    , { 'value': 'scheduled', 'text': 'Scheduled' }
    , { 'value': 'did_not_start', 'text': 'Did not start' }
    , { 'value': 'all_excl_hidden', 'text': 'All but hidden' }
    , { 'value': 'all', 'text': 'All' }
];

var filterJobsMenuItems = [{ 'value': 'running', 'text': 'Running' }
    , { 'value': 'completed', 'text': 'Completed' }
    , { 'value': 'failed', 'text': 'Failed' }
    , { 'value': 'all', 'text': 'Show all' }
];

var sortFlowsMenuItems = [{ 'value': 'trigger_time', 'text': 'Trigger time' }
    , { 'value': 'flow_job_name', 'text': 'Flow' }
    , { 'value': 'flow_run_id', 'text': 'Flow Run ID' }
    , { 'value': 'start_dts', 'text': 'Start time' }
    , { 'value': 'end_dts', 'text': 'End time' }
    , { 'value': 'elapsed_time', 'text': 'Elapsed time' }
];

var sortJobsMenuItems = [{ 'value': 'job_seq_nr', 'text': 'Flow/Job sequence number' }
    , { 'value': 'flow_job_name', 'text': 'Flow/Job' }
    , { 'value': 'job_run_id', 'text': 'Job Run ID' }
    , { 'value': 'start_dts', 'text': 'Start time' }
    , { 'value': 'end_dts', 'text': 'End time' }
    , { 'value': 'elapsed_time', 'text': 'Elapsed time' }
];

var navMenuItems = [];

// Close menu's on any click outside them */
$(document).click(function (event) {
    var target = event.target;
    while (target && !target.id) {
        target = target.parentNode;
    }
    if (target) {
        if ((target.id != 'btnNavigate') && ($(target).closest("#menuNavigate").attr('id') != 'menuNavigate')) {
            $('#menuNavigate').remove();
        }
        if ((target.id != 'btnSort') && ($(target).closest("#menuSort").attr('id') != 'menuSort')) {
            $('#menuSort').remove();
        }
        if ((target.id != 'btnFilter') && ($(target).closest("#menuFilter").attr('id') != 'menuFilter')) {
            $('#menuFilter').remove();
        }
        if ((target.id != 'btnNavbar') && ($(target).closest("#menuNavbar").attr('id') != 'menuNavbar')) {
            $('#menuNavbar').remove();
        }
        if ((target.id != 'viewlogOptionsButton') && ($(target).closest("#viewlogOptionsMenu").attr('id') != 'viewlogOptionsMenu')) {
            $('#viewlogOptionsMenu').remove();
        }
        if ((target.id != 'btnFilterLabel')
            && ($(target).closest("#menuLabels").attr('id') != 'menuLabels')
            && (target.id != 'menuLabels')) {
            $('#menuLabels').remove();
        }
        if ((target.id != 'rundate')
            && ($(target).closest("#dialogRundate").attr('id') != 'dialogRundate')
            && (target.id != 'dialogRundate')) {
            $('#dialogRundate').remove();
        }

    }
})

function setResults1Size() {
    var results1Height = $(window).height() - $("#dimon-menubar").height() - $("#dimon-navbar").height() - $("#dimon-footer").height() - 55;
    var results1Width = $(window).width() - 35;
    $("#results1").height(results1Height);
    $("#results1").width(results1Width);
}//setResults1Size

function setViewLogContentSize() {
    var viewlogContentHeight = $(".ui-dialog").height() - $(".ui-dialog-titlebar").height() - $("#viewlogHeader").height() - $(".ui-dialog-buttonpane").height() - 60;
    $("#viewlogContent").height(viewlogContentHeight);
}//setViewLogContentSize

function setSearchSize() {
    var sortButtonLeft = $("#btnSort").position().left;
    var searchLeft = $("#search").position().left;
    var searchWidth = Math.max(100, sortButtonLeft - searchLeft - 400);
    $("#search").width(searchWidth);
}//setSearchSize

$(window).resize(function () {
    setSearchSize();
    setResults1Size();
});

function keepAlive() {

    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: {
            "_program": getSPName('dimonKeepAlive')
        }
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('keepAlive', XMLHttpRequest, textStatus, errorThrown);
        }
    });

}//keepAlive


// JQuery initialization
$(function () {

    $("#app").html('<div id="dimon-menubar">'
        + '<a href="#" id="linkHome"><img id="dimon-logo"></a>'
        + '<span id="navTitle" class="dimon-menuitem left"></span>'
        + '<button id="btnClearSearch" class="dimon-menuitem left">Clear search</button>'
        + '<input type="text" id="search" class="dimon-menuitem left" placeholder="Search" />'
        + '<button id="btnSettings" class="dimon-menuitem right">Settings</button>'
        + '<button id="btnFilter" class="dimon-menuitem right">Filter</button>'
        + '<button id="btnSort" class="dimon-menuitem right">Sort</button>'
        + '<button id="btnNavigate" class="dimon-menuitem right">Navigate</button>'
        + '<button id="btnFilterLabel" class="dimon-menuitem left">Filter on label</button>'
        + '<button id="btnLabels" class="dimon-menuitem left">Label flows</button>'
        + '</div>'
        + '<div id="dimon-navbar"></div>'
        + '<div id="results1"></div>'
        + '<div id="dimon-footer"></div>'
    );


    // get settings from cookies
    settings.filterFlows = (Cookies.get('dimonFilterFlows') == null ? 'all_excl_hidden' : Cookies.get('dimonFilterFlows'));
    settings.filterJobs = (Cookies.get('dimonFilterJobs') == null ? 'all' : Cookies.get('dimonFilterJobs'));
    settings.sortFlows = (Cookies.get('dimonSortFlows') == null ? 'trigger_time desc' : Cookies.get('dimonSortFlows'));
    settings.sortJobs = (Cookies.get('dimonSortJobs') == null ? 'job_seq_nr asc' : Cookies.get('dimonSortJobs'));
    settings.autorefresh_interval = (Cookies.get('dimonAutoRefreshInterval') == null ? 5 : Cookies.get('dimonAutoRefreshInterval'));
    settings.rundateHistDays = (Cookies.get('dimonRundateHistDays') == null ? 0 : Cookies.get('dimonRundateHistDays'));

    $(document).tooltip();

    $("#dimon-logo").attr("src", settings.imgroot + '/dimon-logo.png'); // set logo
    $("#linkHome").click(function () {
        window.location.href = settings.urlSPA + '?_program=' + getSPName('dimon');
    });

    $('#search').button()
        .keydown(function (event) {
            if (event.keyCode == 13) { // on enter
                refresh();
            }
        })
        ;

    $("#btnClearSearch").button({
        icons: { primary: 'ui-icon-close' }
        , text: false
    })
        .click(function () { clearSearch(); });


    function clearSearch() {
        $("#search").val("");
        refresh();
    }

    $("#btnFilterLabel").button({
        icons: { primary: 'ui-icon-triangle-1-s' }
        , text: false
    })
        .click(function (event) {
            if ($('#menuLabels').length) {
                // remove the menu if it already exists
                $('#menuLabels').remove();
            } else {
                // create and show the menu
                createFilterLabelMenu();
                $("#menuLabels").show();
            }
        });

    $("#btnLabels").button({
        icons: { primary: 'ui-icon-tag' }
        , text: false
    })
        .click(function () { labels(); });

    $("#btnNavigate").button({ icons: { secondary: "ui-icon-arrowthick-1-e" } })
        .click(function (event) {
            if ($('#menuNavigate').length) {
                // remove the menu if it already exists
                $('#menuNavigate').remove();
            } else {
                createNavigateMenu();
            }
        });

    $("#btnSettings").button({
        icons: { primary: 'ui-icon-gear' }
        , text: false
    }).click(function () { getSettings(); });

    $("#btnFilter").button({ icons: { secondary: "ui-icon-triangle-1-s" } })
        .click(function (event) {
            if ($('#menuFilter').length) {
                // remove the menu if it already exists
                $('#menuFilter').remove();
            } else {
                createFilterMenu();
            }
        });

    $("#btnSort").button()
        .click(function (event) {
            if ($('#menuSort').length) {
                // remove the menu if it already exists
                $('#menuSort').remove();
            } else {
                createSortMenu();
            }
        });

    // get navigate menu items
    $.ajax({
        url: settings.urlSPA
        , data: $.extend({}
            , {
                "_program": getSPName('dimonNavMenu')
                //, "_debug": _debug
            })
        , cache: false
        , timeout: ajaxTimeout
        , success: function (data) {

            navMenuItems = $.parseJSON(data).items;

            // set navTitle - find http://hostname:port in navMenuItems.url
            var thisLocation = location.protocol + '//' + location.hostname + (location.port ? ':' + location.port : '');
            for (i = 0; i < navMenuItems.length; i++) {
                if (navMenuItems[i].url.indexOf(thisLocation) == 0) {
                    $("#navTitle").html(navMenuItems[i].text);
                    break;
                }
            }
        }

        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            refreshFlowsRunning = false;
            handleAjaxError('refreshFlows', XMLHttpRequest, textStatus, errorThrown);
        }
    });


    // set #dimon-navbar height
    $("#dimon-navbar").html('<div style="margin:1.15em;"><span class="l systemtitle">&nbsp;</span><div>');

    _debug = (getUrlParameter('_debug') != null ? getUrlParameter('_debug') : 0);

    var srun_date = '';
    var path = getUrlParameter('path');
    if (path) {
    } else {
        srun_date = $.datepicker.formatDate('ddMyy', new Date());
        path = '//_' + srun_date;
    }
    navigate(path);
    setSearchSize();

    // Keep the Stored Process Server session alive by running the keepAlive Stored Process once every 5 minutes
    window.setInterval("keepAlive()", 300000);

});


function labels(initialSelectLabel, message) {

    var tableAvailableFlows;
    var tableSelectedFlows
    var tableLabels;
    var selections;
    var sasdata;
    var workLabels;
    var workAvaFlows;
    var workSelFlows;
    var selectedLabel;
    var isDirty = false;

    var dialog = $('<div id="dialogFlowTags">'
        + '  <div id="labelsStatusMessage"><div id="labelsStatusMessageInner"></div></div>'
        + '  <div style="width:100%">'
        + '    <div style="width:35%; float:left">'
        + '      <h3>Label</h3>'
        + '      Filter: <input type="text" id="textFilterLabels" />'
        + '      <button id="btnClearTextFilterLabels">Clear</button>'
        + '      <button id="btnNewLabel">New</button>'
        + '      <button id="btnDeleteLabel">Delete</button>'
        + '      <table id="tableLabels" style="cursor:default">'
        + '        <thead>'
        + '          <tr>'
        + '            <th></th>'
        + '          </tr>'
        + '        </thead>'
        + '      </table>'
        + '    </div>'
        + '    <div style="width:10%; float:left; text-align:center">'
        + '      <div style="display: inline-block; margin-top:200px;">'
        + '      </div>'
        + '    </div>'
        + '    <div style="width:20%; float:left">'
        + '      <h3>Available flows</h3>'
        + '      Filter: <input type="text" id="filterAvailableFlows" />'
        + '      <button id="btnClearTextAvailableFlows">Clear</button>'
        + '      <table id="tableAvailableFlows" style="cursor:default">'
        + '        <thead>'
        + '          <tr>'
        + '            <th></th>'
        + '            <th></th>'
        + '          </tr>'
        + '        </thead>'
        + '      </table>'
        + '    </div>'
        + '    <div style="width:10%; float:left; text-align:center">'
        + '      <div style="display: inline-block; margin-top:200px;">'
        + '        <button id="btnAddToSelected">&gt;</button><br />'
        + '        <button id="btnAddAllToSelected">&gt;&gt;</button><br />'
        + '        <button id="btnRemoveAllFromSelected">&lt;&lt;</button><br />'
        + '        <button id="btnRemoveFromSelected">&lt;</button>'
        + '      </div>'
        + '    </div>'
        + '    <div style="width:20%; float:left">'
        + '      <h3>Selected flows</h3>'
        + '      Filter: <input type="text" id="filterSelectedFlows" />'
        + '      <button id="btnClearTextSelectedFlows">Clear</button>'
        + '      <table id="tableSelectedFlows" style="cursor:default">'
        + '        <thead>'
        + '          <tr>'
        + '            <th></th>'
        + '            <th></th>'
        + '          </tr>'
        + '        </thead>'
        + '      </table>'
        + '      <button id="btnSaveLabels">Apply</button>'
        + '    </div>'
        + '  </div>'
        + '</div>').appendTo('body');

    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
            refresh();
        }
        , title: 'Label flows'
        , width: 1400
        , height: 720
        , modal: true
        , buttons: {
            "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });

    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: { "_program": getSPName('dimonGetFLowLabels') }
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , dataype: 'json'
        , success: function (response) {

            sasdata = $.parseJSON(response).data;
            selections = sasdata.selections;

            // copy selections to working copy workSelections
            workSelections = [];
            for (var i = 0; i < sasdata.selections.length; i++)
                workSelections[i] = sasdata.selections[i].slice();

            // copy labels to working copy workLabels for Labels table and load table from it
            workLabels = [];
            for (var i = 0; i < sasdata.labels.length; i++) {
                if (sasdata.labels[i][1] != '*')
                   workLabels[i] = sasdata.labels[i].slice();
            }
            reloadLabels(workLabels);
            reloadAvailableFlows(workAvaFlows); // initially empty
            reloadSelectedFlows(workSelFlows); // initially empty

            // label select handler
            tableLabels.on('select.dt', function (e, dt, type, indexes) {

                // reset isDirty
                isDirty = false;
                confirmedCancel = false;

                selectedLabel = tableLabels.row(indexes).data()[0].toString();

                // create array selectedFlows to contain flow_ids of selected Label
                var selectedFlows = [];
                selections.forEach(function (element) {
                    if (element[0].label == selectedLabel) {
                        selectedFlows.push(element[0].flow_id);
                    }
                });

                // traverse the list of available flows and copy them to workAvaFlows or workSelFlows depending on
                // whether it is selected (exists in selectedFlows)
                workAvaFlows = [];
                workSelFlows = [];
                for (var i = 0; i < sasdata.flows.length; i++) {
                    var found = false;
                    for (var j = 0; j < selectedFlows.length; j++) {
                        if (sasdata.flows[i][0] == selectedFlows[j]) {
                            found = true;
                        }
                    }
                    if (found) {
                        workSelFlows.push(sasdata.flows[i].slice());
                    } else {
                        workAvaFlows.push(sasdata.flows[i].slice());
                    }
                }
                refreshFlows();
                updateLabelButtons();

            });

            // label deselect handler
            tableLabels.on('deselect.dt', function (e, dt, type, indexes) {
                deselectedLabel = tableLabels.row(indexes).data()[0].toString();
                deselectConfirmedCancel = false;
                isDirty = false;
                workAvaFlows = [];
                workSelFlows = [];
                refreshFlows();
                updateLabelButtons();
            });

            // Available Flows doubleclick handler
            tableAvailableFlows.on('dblclick', 'tr', function (e, dt, type, indexes) {
                var selectedFlowId = tableAvailableFlows.row(this).data()[0];
                removeFromAvailableFlows(selectedFlowId);
                addToSelectedFlows(selectedFlowId);
                refreshFlows();
            });

            // Available Flows singleclick select handler
            tableAvailableFlows.on('select.dt', function (e, dt, type, indexes) {
                updateFlowsButtons();
            });
            // Available Flows singleclick deselect handler
            tableAvailableFlows.on('deselect.dt', function (e, dt, type, indexes) {
                updateFlowsButtons();
            });

            // Selected Flows doubleclick handler
            tableSelectedFlows.on('dblclick', 'tr', function (e, dt, type, indexes) {
                var selectedFlowId = tableSelectedFlows.row(this).data()[0];
                removeFromSelectedFlows(selectedFlowId);
                addToAvailableFlows(selectedFlowId);
                refreshFlows();
            });
            // Selected Flows singleclick select handler
            tableSelectedFlows.on('select.dt', function (e, dt, type, indexes) {
                updateFlowsButtons();
            });
            // Selected Flows singleclick select handler
            tableSelectedFlows.on('deselect.dt', function (e, dt, type, indexes) {
                updateFlowsButtons();
            });

            // select an initial label if it was passed on the function call
            if (initialSelectLabel != undefined) {
                selectLabel(initialSelectLabel);
            }

            // display message if it was passed on the function call
            if (message != undefined) {
                $("#labelsStatusMessageInner").html(message);
                $("#labelsStatusMessage").slideDown(0).delay(2000).slideUp(0);
            }

        }

        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('keepAlive', XMLHttpRequest, textStatus, errorThrown);
        }
    });

    $("#filterAvailableFlows").button().css({
        'font': 'inherit',
        'color': 'inherit',
        'background-color': 'white',
        'text-align': 'left',
        'outline': 'none',
        'cursor': 'text',
        'width': '50%'
    });

    $("#filterSelectedFlows").button().css({
        'font': 'inherit',
        'color': 'inherit',
        'background-color': 'white',
        'text-align': 'left',
        'outline': 'none',
        'cursor': 'text',
        'width': '50%'
    });

    $("#textFilterLabels").button().css({
        'font': 'inherit',
        'color': 'inherit',
        'background-color': 'white',
        'text-align': 'left',
        'outline': 'none',
        'cursor': 'text',
        'width': '30%'
    });

    $("#btnClearTextFilterLabels").button({
        icons: { primary: 'ui-icon-close' }
        , text: false
    }).click(function () {
        $('#textFilterLabels').val("");
        refreshLabels();
        $('.ui-tooltip').remove(); // remove tooltip since it remains after button disable
    });

    $("#btnNewLabel").button().click(function () {
        var newLabel = [];
        newLabel[0] = $('#textFilterLabels').val();
        workLabels.push(newLabel);
        refreshLabels();
        tableLabels.rows().select();
        tableLabels.search(newLabel).draw(); // filter the labels table
        selectLabel(newLabel[0]);
    });

    $("#btnDeleteLabel").button().click(function () {
        var r = confirm('Are you sure you want to delete label "' + selectedLabel + '"?');
        if (r) {
            $.ajax({
                url: settings.urlSPA
                , data: $.extend({}
                    , {
                        "_program": getSPName('dimonDeleteLabel')
                        , "label": selectedLabel
                    })
                , cache: false
                , timeout: ajaxTimeout
                , success: function (response) {
                    data = $.parseJSON(response);
                    if (data.syscc == 0) {
                        dialog.remove();
                        labels(selectedLabel, "Label '" + selectedLabel + "' was deleted");
                    } else {
                        alert('The request completed with errors (syscc=' + data.syscc + ')\n'
                            + 'The last known error is:\n\n' + data.sysmsg + '\n\n');
                    }
                }
                , error: function (XMLHttpRequest, textStatus, errorThrown) {
                    handleAjaxError('dimonSaveLabels', XMLHttpRequest, textStatus, errorThrown);
                }
            });
        }
    });

    function selectLabel(label) {
        tableLabels.rows().every(function (rowIdx, tableLoop, rowLoop) {
            if (this.data()[0] == label) {
                this.select();
            }
        });
    }

    function updateLabelButtons() {

        // btnDeleteLabel - enable/disable depending on number of selected labels
        var numSelected = tableLabels.rows('.selected').data().length;
        if (numSelected > 0) {
            $("#btnDeleteLabel").prop('disabled', false).removeClass("ui-state-disabled");
        } else {
            $("#btnDeleteLabel").prop('disabled', true).addClass("ui-state-disabled");
        }

        var textFilterLabels = $('#textFilterLabels').val();
        var exists = false;
        for (i = 0; i < workLabels.length; i++) {
            if (String(workLabels[i]).toUpperCase() == String(textFilterLabels).toUpperCase()) exists = true;
        }
        if ((textFilterLabels != '') && (!exists)) {
            // enable New button
            $("#btnNewLabel").prop('disabled', false).removeClass("ui-state-disabled");
            $('#btnNewLabel').button('option', 'label', textFilterLabels + ' (create new)');
        } else {
            // disable New button
            $('#btnNewLabel').button('option', 'label', 'New');
            $("#btnNewLabel").prop('disabled', true).addClass("ui-state-disabled");
        }

        if (textFilterLabels == "") {
            $("#btnClearTextFilterLabels").prop('disabled', true).addClass("ui-state-disabled");
        } else {
            $("#btnClearTextFilterLabels").prop('disabled', false).removeClass("ui-state-disabled");
        }

    }

    function updateFlowsButtons() {

        // var numAvailableFlowsSelected = tableAvailableFlows.rows('.selected').data().length;
        // if (numAvailableFlowsSelected > 0) {
        //     $("#btnAddToSelected").prop('disabled', false).removeClass("ui-state-disabled");
        // } else {
        //     $("#btnAddToSelected").prop('disabled', true).addClass("ui-state-disabled");
        // }

        // var numSelectedFlowsSelected = tableSelectedFlows.rows('.selected').data().length;
        // if (numSelectedFlowsSelected > 0) {
        //     $("#btnRemoveFromSelected").prop('disabled', false).removeClass("ui-state-disabled");
        // } else {
        //     $("#btnRemoveFromSelected").prop('disabled', true).addClass("ui-state-disabled");
        // }

        // var numAvailableFlows = tableAvailableFlows.rows().data({ page: 'current' }).length;
        // if (numAvailableFlows > 0) {
        //     $("#btnAddAllToSelected").prop('disabled', false).removeClass("ui-state-disabled");
        // } else {
        //     $("#btnAddAllToSelected").prop('disabled', true).addClass("ui-state-disabled");
        // }

        // var numSelectedFlows = tableSelectedFlows.rows().data({ page: 'current' }).length;
        // if (numSelectedFlows > 0) {
        //     $("#btnRemoveAllFromSelected").prop('disabled', false).removeClass("ui-state-disabled");
        // } else {
        //     $("#btnRemoveAllFromSelected").prop('disabled', true).addClass("ui-state-disabled");
        // }

    }

    $("#btnClearTextAvailableFlows").button({
        icons: { primary: 'ui-icon-close' }
        , text: false
    }).click(function () {
        $('#filterAvailableFlows').val("");
        refreshAvailableFlows();
        $('.ui-tooltip').remove(); // remove tooltip since it remains after button disable
    });

    $("#btnClearTextSelectedFlows").button({
        icons: { primary: 'ui-icon-close' }
        , text: false
    }).click(function () {
        $('#filterSelectedFlows').val("");
        refreshSelectedFlows();
        $('.ui-tooltip').remove(); // remove tooltip since it remains after button disable
    });

    function refreshLabels() {
        tableLabels.destroy();
        reloadLabels(workLabels);
    }

    function refreshFlows() {
        refreshAvailableFlows();
        refreshSelectedFlows();
        updateFlowsButtons();
    }

    function refreshAvailableFlows() {
        tableAvailableFlows.destroy();
        reloadAvailableFlows(workAvaFlows);
    }

    function refreshSelectedFlows() {
        tableSelectedFlows.destroy();
        reloadSelectedFlows(workSelFlows);
    }

    $("#btnAddToSelected").button().css({ width: "50px" }).click(function () {
        var tSelections = tableAvailableFlows.rows('.selected').data().slice();
        for (var i = 0; i < tSelections.length; i++) {
            var selectedFlowId = tSelections[i][0]; // [0] contains the flow_id
            removeFromAvailableFlows(selectedFlowId);
            addToSelectedFlows(selectedFlowId);
        }
        refreshFlows();
    });

    $("#btnRemoveFromSelected").button().css({ width: "50px" }).click(function () {
        var tSelections = tableSelectedFlows.rows('.selected').data().slice();
        for (var i = 0; i < tSelections.length; i++) {
            var selectedFlowId = tSelections[i][0]; // [0] contains the flow_id
            removeFromSelectedFlows(selectedFlowId);
            addToAvailableFlows(selectedFlowId);
        }
        refreshFlows();
    });

    $("#btnAddAllToSelected").button().css({ width: "50px" }).click(function () {
        var tSelections = tableAvailableFlows.rows({ page: 'current' }).data().slice();
        for (var i = 0; i < tSelections.length; i++) {
            var selectedFlowId = tSelections[i][0]; // [0] contains the flow_id
            removeFromAvailableFlows(selectedFlowId);
            addToSelectedFlows(selectedFlowId);
        }
        refreshFlows();
    });

    $("#btnRemoveAllFromSelected").button().css({ width: "50px" }).click(function () {
        var tSelections = tableSelectedFlows.rows().data({ page: 'current' }).slice();
        for (var i = 0; i < tSelections.length; i++) {
            var selectedFlowId = tSelections[i][0]; // [0] contains the flow_id
            removeFromSelectedFlows(selectedFlowId);
            addToAvailableFlows(selectedFlowId);
        }
        refreshFlows();
    });


    function removeFromAvailableFlows(flow_id) {
        for (var i = 0; i < workAvaFlows.length; i++) {
            if (workAvaFlows[i][0] == flow_id) {
                workAvaFlows.splice(i, 1);
            }
        }
        isDirty = true;
    }
    function addToSelectedFlows(flow_id) {
        for (var i = 0; i < sasdata.flows.length; i++) {
            if (sasdata.flows[i][0] == flow_id) {
                workSelFlows.push(sasdata.flows[i].slice());
            }
        }
        isDirty = true;
    }

    function removeFromSelectedFlows(flow_id) {
        for (var i = 0; i < workSelFlows.length; i++) {
            if (workSelFlows[i][0] == flow_id) {
                workSelFlows.splice(i, 1);
            }
        }
        isDirty = true;
    }

    function addToAvailableFlows(flow_id) {
        for (var i = 0; i < sasdata.flows.length; i++) {
            if (sasdata.flows[i][0] == flow_id) {
                workAvaFlows.push(sasdata.flows[i].slice());
            }
        }
        isDirty = true;
    }


    $("#textFlows").focus();


    $("#btnSaveLabels").button().css({ 'width': '100%', 'margin-top': '10px' })
        .click(function () {
            $.ajax({
                url: settings.urlSPA
                , data: $.extend({}
                    , {
                        "_program": getSPName('dimonSaveLabels')
                        , "label": selectedLabel
                        , "flows": JSON.stringify(workSelFlows)
                    })
                , cache: false
                , timeout: ajaxTimeout
                , success: function (response) {
                    data = $.parseJSON(response);
                    if (data.syscc == 0) {
                        dialog.remove();
                        labels(selectedLabel, "Label '" + selectedLabel + "' was saved");
                    } else {
                        alert('The request completed with errors (syscc=' + data.syscc + ')\n'
                            + 'The last known error is:\n\n' + data.sysmsg + '\n\n');
                    }
                }
                , error: function (XMLHttpRequest, textStatus, errorThrown) {
                    handleAjaxError('dimonSaveLabels', XMLHttpRequest, textStatus, errorThrown);
                }
            });

        });


    function reloadLabels(data) {

        tableLabels = $('#tableLabels').DataTable({
            data: data,
            paging: false,
            scrollY: 400,
            select: {
                style: 'single',
            }
        });
        updateLabelButtons();

        // hide the Tags datatables search box (but leave the search functionality)
        $("#tableLabels_filter").css({ 'display': 'none' });
        $('#textFilterLabels').on('keyup', function () {
            tableLabels.search(this.value).draw(); // filter the labels table
            updateLabelButtons();
        });

    }

    function reloadAvailableFlows(data) {

        $('#tableAvailableFlows').empty();
        tableAvailableFlows = $('#tableAvailableFlows').DataTable({
            data: data,
            paging: false,
            scrollY: 400,
            columnDefs: [{
                targets: 0,
                visible: false,
                searchable: false
            },
            {
                className: 'dt-head-left',
                targets: 1
            }],
            select: {
                style: 'os'
            }
        });
        tableAvailableFlows.search(filterAvailableFlows.value).draw(); // apply filter

        // hide the Flows datatables search box (but leave the search functionality)
        $("#tableAvailableFlows_filter").css({ 'display': 'none' });
        $('#filterAvailableFlows').on('keyup', function () {
            // filter the table
            tableAvailableFlows.search(this.value).draw();
            updateFlowsButtons();
        });

    }

    function reloadSelectedFlows(data) {
        tableSelectedFlows = $('#tableSelectedFlows').DataTable({
            data: data,
            paging: false,
            scrollY: 400,
            columnDefs: [
                {
                    targets: 0,
                    visible: false,
                    searchable: false
                },
                {
                    className: 'dt-head-left',
                    targets: 1
                }],
            select: {
                style: 'os'
            }
        });
        tableSelectedFlows.search(filterSelectedFlows.value).draw(); // apply filter

        // hide the Flows datatables search box (but leave the search functionality)
        $("#tableSelectedFlows_filter").css({ 'display': 'none' });
        $('#filterSelectedFlows').on('keyup', function () {
            // filter the table
            tableSelectedFlows.search(this.value).draw();
            updateFlowsButtons();
        });

        // set btnSaveLabels button status
        if (isDirty) {
            $("#btnSaveLabels").prop('disabled', false).removeClass("ui-state-disabled");
        } else {
            $("#btnSaveLabels").prop('disabled', true).addClass("ui-state-disabled");
        }

    }

}// flowGroups


function getSettings() {

    var dialog = $('<div id="dialogSettings">'
        // + '<p>'
        // + '<label for="autorefresh-interval" style="float:left">Auto-refresh interval:</label>'
        // + '<div id="slider-autorefresh-interval" style="float:left; width:400px; margin-left: 10px;"></div>'
        // + '<input type="text" id="autorefresh-interval" readonly style="border:0; float:left; margin-left: 10px;">'
        // + '</p>'
        + '  <div id="tabs">'

        + '    <ul>'
        + '      <li><a href="#tabs-general">General</a></li>'
        + '      <li><a href="#tabs-alerts">Alerts</a></li>'
        + '    </ul>'

        + '    <div id="tabs-general" style="height:500px;">'
        + '      <p>'
        + '      <label for="autorefresh-interval" style="float:left">Auto-refresh interval:</label>'
        + '      <div id="slider-autorefresh-interval" style="float:left; width:400px; margin-left: 10px;"></div>'
        + '      <input type="text" id="autorefresh-interval" readonly style="border:0; float:left; margin-left: 10px;">'
        + '      </p>'
        + '    </div>'

        + '    <div id="tabs-alerts">'
        + '      <div class="row">'
        + '        <div class="column">'
        + '          <h3>Flows</h3>'
        + '          <label for="filterFlows">Filter:&nbsp;</label><input type="text" id="filterFlows" />'
        + '          <button id="btnClearTextFlows">Clear</button>'
        + '          <table id="tableFlows" style="cursor:default">'
        + '            <thead>'
        + '              <tr>'
        + '                <th></th>'
        + '                <th></th>'
        + '              </tr>'
        + '            </thead>'
        + '          </table>'
        + '        </div>'
        + '        <div class="column">'
        + '          <h3>Alerts</h3>'
        + '        </div>'
        + '      </div>'
        + '    </div>'

        + '  </div>'
        + '</div>').appendTo('body');

    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'Settings'
        , width: 1200
        , height: 700
        , modal: true
        , buttons: {
            "Apply": function (event, ui) {
                autorefresh_interval = $("#slider-autorefresh-interval").slider("value");
                settings.autorefresh_interval = autorefresh_interval;
                Cookies.set('dimonAutoRefreshInterval', settings.autorefresh_interval, { expires: 365 });
                $(this).dialog('close');
                refresh();
            }
            , "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });

    $("#tabs").tabs();

    // AUTOREFRESH SLIDER INIT - BEGIN
    $("#slider-autorefresh-interval").slider({
        range: "min",
        value: settings.autorefresh_interval,
        min: 0,
        max: autorefresh_intervals.length - 1,
        step: 1,
        animate: true,
        slide: function (event, ui) {
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
    // AUTOREFRESH SLIDER INIT - END

    // ALERTS - BEGIN
    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: { "_program": getSPName('dimonGetFLowLabels') }
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , dataype: 'json'
        , success: function (response) {

            sasdata = $.parseJSON(response).data;
            $('#tableFlows').empty();
            tableFlows = $('#tableFlows').DataTable({
                data: sasdata.flows,
                paging: false,
                scrollY: 350,
                columnDefs: [{
                    targets: 0,
                    visible: false,
                    searchable: false
                },
                {
                    className: 'dt-head-left',
                    targets: 1
                }],
                select: {
                    style: 'os'
                }
            });
            tableFlows.search(filterFlows.value).draw(); // apply filter

            // hide the Flows datatables search box (but leave the search functionality)
            $("#tableFlows_filter").css({ 'display': 'none' });
            $('#filterFlows').on('keyup', function () {
                // filter the table
                tableFlows.search(this.value).draw();
                //updateFlowsButtons();
            });

            // label select handler
            tableFlows.on('select.dt', function (e, dt, type, indexes) {

                // reset isDirty
                isDirty = false;
                confirmedCancel = false;

                selectedLabel = tableFlows.row(indexes).data()[0].toString();
                alert(selectedLabel);
            });
            
        }

        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('keepAlive', XMLHttpRequest, textStatus, errorThrown);
        }
    });

    // ALERTS - END

    $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//getSettings


function updateFilterButtonLabel() {

    var filterLabel = '';

    switch (settings.currentView) {
        case "Flows":
            var menuItems = filterFlowsMenuItems;
            var filter = settings.filterFlows;
            break;
        case "Jobs":
            var menuItems = filterJobsMenuItems;
            var filter = settings.filterJobs;
            break;
        case "Steps":
            var menuItems = [];
            var filter = '';
            break;
        default:
    }

    var filterLabel = '';
    for (i = 0; i < menuItems.length; i++) {
        if (menuItems[i].value == filter) {
            filterLabel = menuItems[i].text;
        }
    }
    $("#btnFilter").button({ label: 'Show: ' + filterLabel });

}//updateFilterButtonLabel


function updateSortButtonLabel() {

    var sortLabel = '';

    switch (settings.currentView) {
        case "Flows":
            var menuItems = sortFlowsMenuItems;
            var sortColumn = settings.sortFlows.split(' ')[0];
            var sortDirection = settings.sortFlows.split(' ')[1];
            break;
        case "Jobs":
            var menuItems = sortJobsMenuItems;
            var sortColumn = settings.sortJobs.split(' ')[0];
            var sortDirection = settings.sortJobs.split(' ')[1];
            break;
        case "Steps":
            var menuItems = [];
            var sortColumn = '';
            var sortDirection = '';
            break;
        default:
    }

    for (i = 0; i < menuItems.length; i++) {
        if (menuItems[i].value == sortColumn) {
            sortLabel = menuItems[i].text;
        }
    }

    $("#btnSort").button({
        icons: { secondary: (sortDirection == 'asc' ? "ui-icon-arrowthick-1-s" : "ui-icon-arrowthick-1-n") }
        , label: 'Sort: ' + sortLabel
    })

}//updateSortButtonLabel


function createFilterMenu() {

    var filterMenuItems = [];
    var currentFilter = '';
    switch (settings.currentView) {

        case "Flows":
            filterMenuItems = filterFlowsMenuItems;
            currentFilter = settings.filterFlows;
            break;

        case "Jobs":
            filterMenuItems = filterJobsMenuItems;
            currentFilter = settings.filterJobs;
            break;

        default:
            filterMenuItems = [];
            currentFilter = '';
    }

    var s = '';
    s += '<ul class="dropdown-menu">';

    // Add Filter items
    for (i = 0; i < filterMenuItems.length; i++) {
        s += '<li class="li-dropdown-item li-dropdown-filter-item ui-widget" id="filter-' + filterMenuItems[i].value + '"><div>'
            + '<span class="ui-icon ui-icon-dropdown-item ' + (currentFilter == filterMenuItems[i].value ? 'ui-icon-check' : 'ui-icon-blank') + '"></span>'
            + '<span class="text-dropdown-item">' + filterMenuItems[i].text + '</span>'
            + '</div><br></li>'
            ;
    }

    s += '</ul>';

    var menuWidth = 193;
    button = $("#btnFilter");
    var buttonPosition = button.position();
    var buttonLeft = buttonPosition.left;
    var buttonBottom = buttonPosition.top + button.height() + 6;
    var menuLeft = buttonLeft + button.width() - menuWidth;
    $("#menuFilter").remove(); // remove menu in case it already exists
    var menuFilter = $('<div id="menuFilter" style="display:block;'
        + 'position:absolute;'
        + 'top:' + buttonBottom + 'px;'
        + 'left:' + menuLeft + 'px;'
        + 'width:' + menuWidth + 'px;'
        + 'z-index:1001;'
        + '" class="dropdown-menu"></div>').appendTo('body');
    $("#menuFilter").html(s);
    $('.li-dropdown-filter-item').click(function () { filter($(this).attr('id').split('-')[1]); });

}//createFilterMenu


function createNavigateMenu() {

    var currentNavigate = '';
    var s = '';
    s += '<ul class="dropdown-menu">';

    // Add items
    if (navMenuItems.length > 0) {
        for (i = 0; i < navMenuItems.length; i++) {
            s += '<li class="li-dropdown-item li-dropdown-navigate-item ui-widget" id="navigate-' + i + '"><div>'
                + '<span class="ui-icon ui-icon-dropdown-item ' + (currentNavigate == navMenuItems[i].value ? 'ui-icon-check' : 'ui-icon-blank') + '"></span>'
                + '<span class="text-dropdown-item">' + navMenuItems[i].text + '</span>'
                + '</div><br></li>'
                ;
        }
    } else {
        s += '<li class="li-dropdown-item li-dropdown-navigate-item ui-widget" id="navigate-null"><div>'
            + '<span class="ui-icon ui-icon-dropdown-item ui-icon-blank"></span>'
            + '<span class="text-dropdown-item">&lt;no items&gt;</span>'
            + '</div><br></li>'
            ;
    }

    s += '</ul>';

    var menuWidth = 193;
    button = $("#btnNavigate");
    var buttonPosition = button.position();
    var buttonBottom = buttonPosition.top + button.height() + 6;
    var menuLeft = buttonPosition.left;
    $("#menuNavigate").remove(); // remove menu in case it already exists
    var menuNavigate = $('<div id="menuNavigate" style="display:block;'
        + 'position:absolute;'
        + 'top:' + buttonBottom + 'px;'
        + 'left:' + menuLeft + 'px;'
        + 'width:' + menuWidth + 'px;'
        + 'z-index:1001;'
        + '" class="dropdown-menu"></div>').appendTo('body');
    $("#menuNavigate").html(s);
    $('.li-dropdown-navigate-item').click(function () {
        $("#menuNavigate").remove(); // remove the menu on click
        var itemnr = $(this).attr('id').split('-')[1];
        if (navMenuItems[itemnr] != undefined) {
            window.location.href = navMenuItems[itemnr].url;
        }
    });

}//createNavigateMenu


function createFilterLabelMenu() {

    inputSearch = $("#search");
    var inputPosition = inputSearch.offset();
    var inputLeft = inputPosition.left;
    var inputBottom = inputPosition.top + inputSearch.height() + 14;
    var inputWidth = inputSearch.width() + 25;
    $("#menuLabels").remove(); // remove menu in case it already exists
    var menuLabels = $('<div id="menuLabels" style="display:block;'
        + 'position:absolute;'
        + 'top:' + inputBottom + 'px;'
        + 'left:' + inputLeft + 'px;'
        + 'width:' + inputWidth + 'px;'
        + 'z-index:1001;'
        + '" class="dropdown-menu"></div>').appendTo('body');
    $("#menuLabels").html('<span style="margin:10px;">Loading...</span>'); // show loading in menu

    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: { "_program": getSPName('dimonGetFLowLabels') }
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , dataype: 'json'
        , success: function (response) {

            sasdata = $.parseJSON(response).data;
            var labels = sasdata.labels;

            var currentLabel = '';

            // createdropdown menu
            var s = '<ul class="dropdown-menu">';
            for (i = 0; i < labels.length; i++) {
                if (labels[i][1] == '*') labels[i][0] = labels[i][0] + ' *';
                s += '<li class="li-dropdown-item li-dropdown-label-item ui-widget" id="label_' + labels[i][0].replace(/ /g, '-') + '"><div>'
                    + '<span class="ui-icon ui-icon-dropdown-item ui-icon-blank"></span>'
                    + '<span class="text-dropdown-item">' + labels[i][0] + '</span>'
                    + '</div><br></li>'
                    ;
            }
            s += '</ul>';

            $("#menuLabels").html(s);
            $('.li-dropdown-label-item').click(function () {
                $("#search").val("label:" + $(this).attr('id').split('_')[1]);
                refresh();
                $("#menuLabels").remove(); // remove menu in case it already exists
            });

        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('keepAlive', XMLHttpRequest, textStatus, errorThrown);
        }

    });

}//createFilterLabelMenu


function filter(options) {

    switch (settings.currentView) {
        case "Flows":
            settings.filterFlows = options;
            Cookies.set('dimonFilterFlows', options, { expires: 365 });
            break;
        case "Jobs":
            settings.filterJobs = options;
            Cookies.set('dimonFilterJobs', options, { expires: 365 });
            break;
        default:
    }
    setTimeout(function () {
        updateFilterButtonLabel();
        $("#menuFilter").remove();
    }, 500);
    refresh();

}//filter


function createSortMenu() {

    var SortMenuItems = [];
    var currentSort = '';
    switch (settings.currentView) {

        case "Flows":
            sortMenuItems = sortFlowsMenuItems;
            var sortColumn = (settings.sortFlows.split(' ')[0] == null ? 'trigger_time' : settings.sortFlows.split(' ')[0]);
            var sortDirection = (settings.sortFlows.split(' ')[1] == null ? 'desc' : settings.sortFlows.split(' ')[1]);
            break;

        case "Jobs":
            sortMenuItems = sortJobsMenuItems;
            var sortColumn = (settings.sortJobs.split(' ')[0] == null ? 'trigger_time' : settings.sortJobs.split(' ')[0]);
            var sortDirection = (settings.sortJobs.split(' ')[1] == null ? 'desc' : settings.sortJobs.split(' ')[1]);
            break;

        default:
            sortMenuItems = [];
            currentSort = '';
    }

    var s = '';
    s += '<ul class="dropdown-menu">';

    // Add Sort items
    for (i = 0; i < sortMenuItems.length; i++) {
        s += '<li class="li-dropdown-item li-dropdown-sort-item ui-widget" id="sort-' + sortMenuItems[i].value + '"><div>'
            + '<span class="ui-icon ui-icon-dropdown-item ' + (sortColumn == sortMenuItems[i].value ? 'ui-icon-check' : 'ui-icon-blank') + '"></span>'
            + '<span class="text-dropdown-item">' + sortMenuItems[i].text + '</span>';
        if (sortColumn == sortMenuItems[i].value) {
            s += '<span class="ui-icon ui-icon-dropdown-item sortmenu-sort-direction-item ' + (sortDirection == 'asc' ? "ui-icon-arrowthick-1-s" : "ui-icon-arrowthick-1-n") + '"></span>'
        }
        s += '</div><br></li>';
    }

    s += '</ul>';
    menuWidth = 200;
    button = $("#btnSort");
    var buttonPosition = button.position();
    var menuLeft = buttonPosition.left;
    var menuTop = buttonPosition.top + button.height() + 6;
    $("#menuSort").remove(); // remove menu in case it already exists
    var menuSort = $('<div id="menuSort" style="display:block;'
        + 'position:absolute;'
        + 'top:' + menuTop + 'px;'
        + 'left:' + menuLeft + 'px;'
        + 'width:' + menuWidth + 'px;'
        + 'z-index:1001;'
        + '" class="dropdown-menu"></div>').appendTo('body');
    $("#menuSort").html(s);
    $('.li-dropdown-sort-item').click(function () { sort($(this).attr('id').split('-')[1]); });

}//createSortMenu


function sort(sortColumn) {

    var currentSortColumn = '';
    var currentSortOrder = '';

    switch (settings.currentView) {

        case "Flows":
            currentSortColumn = settings.sortFlows.split(' ')[0];
            currentSortOrder = settings.sortFlows.split(' ')[1];
            break;

        case "Jobs":
            currentSortColumn = settings.sortJobs.split(' ')[0];
            currentSortOrder = settings.sortJobs.split(' ')[1];
            break;

        default:

    }

    if (sortColumn == currentSortColumn) {
        sortOrder = (currentSortOrder == 'asc' ? 'desc' : 'asc');// reverse sort order
    } else {
        var sortOrder = 'asc';// default sort order is ascending
    }

    switch (settings.currentView) {

        case "Flows":
            settings.sortFlows = sortColumn + ' ' + sortOrder;
            Cookies.set('dimonSortFlows', settings.sortFlows, { expires: 365 });
            break;

        case "Jobs":
            settings.sortJobs = sortColumn + ' ' + sortOrder;
            Cookies.set('dimonSortJobs', settings.sortJobs, { expires: 365 });
            break;

        default:

    }

    $("#menuSort").remove();
    createSortMenu();
    setTimeout(function () {
        $("#menuSort").remove();
        updateSortButtonLabel();
    }, 500);
    refresh();

}//sort


function getSPName(spname) {
    return settings.sproot + "/" + spname;
}//getSPName


function navigate(path) {

    settings.currentPath = path; // save for refresh
    switch (path.split('_')[0]) {

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

    var s = '<ul class="dropdown-menu">'
        + '<li class="li-dropdown-item" id="copyPath">'
        + '<div><span class="text-dropdown-item  ui-widget">&nbsp;&nbsp;Navigation path</span></div><br>'
        + '</li>'
        + '</ul>';
    button = $("#btnNavbar");
    var menuWidth = 240;
    var buttonPosition = button.position();
    var menuLeft = buttonPosition.left + button.width() - menuWidth;
    var menuTop = buttonPosition.top + button.height() + 8;
    $("#menuNavbar").remove(); // remove menu in case it already exists
    var menuNavbar = $('<div id="menuNavbar" style="display:block;position:absolute;top:' + menuTop + 'px;left:' + menuLeft + 'px;width:' + menuWidth + 'px;z-index:1001;" class="dropdown-menu"></div>').appendTo('body');
    $("#menuNavbar").html(s);
    $("#copyPath").click(function () {
        $("#menuNavbar").remove();
        dialogNavigationPath();
    });
    $("#menuNavbar").show();

}//menuNavbar


function dialogNavigationPath() {

    var dialogWidth = $(window).width() * 0.6;
    var dialogHeight = 175;
    var dialog = $('<div id="dialogNavigationPath">'
        + '<p>'
        + '<input type="text" id="navigationPath">'
        + '</p>'
        + '</div>').appendTo('body');
    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'Navigation Path'
        , width: dialogWidth
        , height: dialogHeight
        , modal: true
        , buttons: {
            "Copy to clipboard": function (event, ui) {
                $("#navigationPath").select();
                document.execCommand("copy");
            }
            , "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });

    var url = $(location).attr('protocol') + '//' + $(location).attr('host') + settings.webroot + '/?path=' + $('#navpath .navpath-item:last').attr('id');
    $("#navigationPath").css("width", dialogWidth - 55).css("text-align", "left").button().val(url);

}//dialogNavigationPath


function Flows(run_date) {

    clearInterval(interval);
    settings.currentView = 'Flows';
    updateFilterButtonLabel();
    updateSortButtonLabel();
    $("#btnFilter").button("enable");
    $("#btnSort").button("enable");
    $("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    refreshFlows(run_date);
    if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
        interval = setInterval("refreshFlows('" + run_date + "')", autorefresh_intervals[settings.autorefresh_interval] * 1000);
    }

}//Flows


function refreshFlows(run_date) {

    if ($("#results1").length) {

        if (!refreshFlowsRunning) {

            refreshFlowsRunning = true;
            $.ajax({
                url: settings.urlSPA
                , data: $.extend({}
                    , {
                        "_program": getSPName('dimonFlows')
                        , "run_date": run_date
                        , "run_date_histdays": settings.rundateHistDays
                        , "filter": settings.filterFlows
                        , "sort": settings.sortFlows
                        , "search": $('#search').val()
                        , "_debug": _debug
                    })
                , cache: false
                , timeout: ajaxTimeout
                , success: function (data) {

                    refreshFlowsRunning = false;
                    handleAjaxSuccess();

                    // To prevent delayed output from SP, check if we're still in Flows view.
                    if (settings.currentView == 'Flows') {

                        $("#results1").html(data);

                        // move SAS-generated report title to #dimon-navbar
                        $("#dimon-navbar").html('<div id="navpath"></div><span id="btnNavbar"></span>');
                        $("#btnNavbar").html(svgDotsVertical).button().click(function () {
                            menuNavbar();
                        });
                        $("#results1 .systitleandfootercontainer").appendTo("#navpath");
                        $("#results1").find('br:first').remove();

                        // move SAS-generated footer to #dimon-footer
                        $("#dimon-footer").html("");
                        $("#results1 .reportfooter").appendTo("#dimon-footer");

                        function createRundateDialog(initRundate) {

                            var dp = $("#rundate");
                            var dpPosition = dp.offset();
                            var dpLeft = dpPosition.left;
                            var dpBottom = dpPosition.top + dp.height() + 2;
                            var dpWidth = dp.width() + 420;
                            $("#dialogRundate").remove(); // remove menu in case it already exists

                            var dialogRundate = $('<div id="dialogRundate" style="display:block;'
                                + 'position:absolute;'
                                + 'top:' + dpBottom + 'px;'
                                + 'left:' + dpLeft + 'px;'
                                + 'width:' + dpWidth + 'px;'
                                + 'z-index:1001;'
                                + '" class="dropdown-menu"></div>').appendTo('body');

                            $("#dialogRundate").html('<div id="dialogRundate">'
                                + '  <div style="float:left">'
                                + '    <div id="datepicker" style="padding:15px;"></div>'
                                + '  </div>'
                                + '  <div style="float:left;">'
                                + '    <div style="padding:15px;">'
                                + '      <table>'
                                + '        <tr><td><label for="inputRundate" class="ui-widget">Selected date:</label></td><td><input type="text" id="inputRundate"></td></tr>'
                                + '        <tr><td><label for="inputRundateHistdays" class="ui-widget">History (in days):</label></td><td><input type="text" id="inputRundateHistdays"></td></tr>'
                                + '        <tr>'
                                + '          <td>'
                                + '            <button id="btnRundateToday" style="margin-top:20px">Today</button>'
                                + '          </td>'
                                + '          <td align="right">'
                                + '            <button id="btnRundateCancel" style="margin-top:20px">Cancel</button>'
                                + '            <button id="btnRundateApply" style="margin-top:20px">Apply</button>'
                                + '          </td>'
                                + '        </tr>'
                                + '      </table>'
                                + '    </div>'
                                + '  </div>'
                                + '</div>'
                            );

                            $("#datepicker").datepicker({
                                dateFormat: "ddMyy"
                                , onSelect: function (date, event) {
                                    $("#inputRundate").val($.datepicker.formatDate('ddMyy', $("#datepicker").datepicker("getDate")));
                                }
                            });

                            // get initial rundate from #rundate and set it on the datepicker and in the input field
                            var rundate = $("#rundate").text().split(" ").pop().substr(0, 9);
                            $("#inputRundate").val(rundate);
                            $("#datepicker").datepicker("setDate", rundate);

                            // make the inputRundate field a spinner
                            $("#inputRundate").spinner({
                                spin: function (event, ui) {
                                    event.preventDefault();
                                    var rundate1 = $("#datepicker").datepicker("getDate");
                                    rundate1.setDate(rundate1.getDate() + ui.value); // ui.value returns the increment value
                                    $("#inputRundate").val($.datepicker.formatDate('ddMyy', rundate1));
                                    $("#inputRundate").change(); // update the datepicker
                                }
                            });

                            // get and set initial rundateHistDays
                            $("#inputRundateHistdays").val(settings.rundateHistDays)
                                .spinner({
                                    min: 0
                                    , max: 365
                                });;

                            // update the datepicker when inputRundate has changed
                            $("#inputRundate").change(function (event) {
                                let value = $(this).val();
                                let format = $("#datepicker").datepicker('option', 'dateFormat');
                                let valueIsValid = false;
                                try {
                                    $.datepicker.parseDate(format, value);
                                    valueIsValid = true;
                                    enableButton($("#btnRundateApply"));
                                    $("#datepicker").datepicker("setDate", $("#inputRundate").val());
                                }
                                catch (e) {
                                    alert('Invalid date entered, it must in the format DDMMMYYYY.')
                                    disableButton($("#btnRundateApply"));
                                }
                            })

                            $("#btnRundateToday").button().click(function () {
                                $("#inputRundate").val($.datepicker.formatDate('ddMyy', new Date()));
                                $("#inputRundate").change(); // update the datepicker
                            });
                            $("#btnRundateCancel").button().click(function () {
                                $("#dialogRundate").remove();
                            });
                            $("#btnRundateApply").button().click(function () {
                                settings.rundateHistDays = $("#inputRundateHistdays").val();
                                Cookies.set('dimonRundateHistDays', settings.rundateHistDays, { expires: 365 });
                                navigate('//_' + $("#inputRundate").val());
                                $("#dialogRundate").remove();
                            });
                        }

                        // rundate click handler
                        $("#rundate").button()
                            .click(function (event) {
                                if ($('#dialogRundate').length) {
                                    // remove the menu if it already exists
                                    $('#dialogRundate').remove();
                                } else {
                                    createRundateDialog();
                                    $("#dialogRundate").show();
                                    $(".navpath-item").addClass('ui-state-hover');
                                }
                            });

                        $(".flow-status-link").click(function () {
                            viewNotesWarningsErrors({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "rc": $(this).attr('id').split('_')[3]
                            });
                        });
                        $(".flow-drilldown-link").click(function () {
                            navigate($(this).attr('id'));
                        });
                        $(".start-dts-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "START_END_TIME"
                            });
                        });
                        $(".end-dts-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "END_TIME"
                            });
                        });
                        $(".elapsed-time-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "ELAPSED_TIME"
                            });
                        });
                        $(".realtime-flows-audit-stats-link").click(function () {
                            realtimeFlowAuditStats($(this).attr('id').split('_')[1]);
                        });
                        $(".dimon-status-progressbar").progressbar()
                            .each(function (i) {
                                var value = parseInt(this.id.split('_')[1]); // get value from id
                                if (isNaN(value)) {
                                    $(this).progressbar("option", "value", false); // no value found -> undeterminate
                                } else {
                                    var progressbarValue = Math.min(100, Math.max(5, value)); //value  min=5%, max=100%
                                    $(this).progressbar("value", progressbarValue);
                                    $(this).find('span').text(value + "%");
                                }
                                $(this).removeClass('ui-corner-all');
                            });
                        $(".trend-sparkline").each(function () {
                            $(this).sparkline('html', { width: '150px', fillColor: undefined })
                                .click(function (e) {
                                    plot({
                                        "flow_run_id": $(this).attr('id').split('_')[1]
                                        , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                        , "flow_job_id": $(this).attr('id').split('_')[3]
                                        , "plot_yvar": "ELAPSED_TIME"
                                    });
                                });

                        });

                        //$(".dimon-bar").addClass('ui-corner-all'); // give gantt bars rounded corners
                        $(":button:contains('Filter')").button("enable");

                        setResults1Size();
                        setSearchSize();

                    }
                }
                , error: function (XMLHttpRequest, textStatus, errorThrown) {
                    refreshFlowsRunning = false;
                    handleAjaxError('refreshFlows', XMLHttpRequest, textStatus, errorThrown);
                }
            });
        }
    }

}//refreshFlows


function Jobs(path) {

    clearInterval(interval);
    settings.currentView = 'Jobs';
    updateFilterButtonLabel();
    updateSortButtonLabel();
    $("#btnFilter").button("enable");
    $("#btnSort").button("enable");
    $("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    refreshJobs(path);
    if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
        interval = setInterval('refreshJobs("' + path + '")', autorefresh_intervals[settings.autorefresh_interval] * 1000);
    }

}//Jobs


function refreshJobs(path) {

    if ($("#results1").length) {

        if (!refreshJobsRunning) {

            refreshJobsRunning = true;
            $.ajax({
                url: settings.urlSPA
                , data: {
                    "_program": getSPName('dimonJobs')
                    , "flow_run_id": path.split('_')[1]
                    , "flow_run_seq_nr": path.split('_')[2]
                    , "flow_job_id": path.split('_')[3]
                    , "run_date": path.split('_')[4]
                    , "filter": settings.filterJobs
                    , "sort": settings.sortJobs
                    //, "search": $('#search').val()
                    , "_debug": _debug
                }
                , cache: false
                , timeout: ajaxTimeout
                , success: function (data) {

                    refreshJobsRunning = false;
                    handleAjaxSuccess();

                    // To prevent delayed output from SP, check if we're still in Jobs view.
                    if (settings.currentView == 'Jobs') {

                        $("#results1").html(data);

                        // move SAS-generated report title to #dimon-navbar
                        $("#dimon-navbar").html('<div id="navpath"></div><span id="btnNavbar"></span>');
                        $("#btnNavbar").html(svgDotsVertical).button().click(function () {
                            menuNavbar();
                        });
                        $("#results1 .systitleandfootercontainer").appendTo("#navpath");
                        $("#results1").find('br:first').remove();

                        // move SAS-generated footer to #dimon-footer
                        $("#dimon-footer").html("");
                        $("#results1 .reportfooter").appendTo("#dimon-footer");

                        $(".navpath-item").button().click(function () { navigate($(this).attr('id')); });

                        $(".flow-status-link").click(function () {
                            viewNotesWarningsErrors({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "rc": $(this).attr('id').split('_')[3]
                                , "flow_job_id": $(this).attr('id').split('_')[4]
                            });
                        });
                        $(".job-status-link").click(function () {
                            viewNotesWarningsErrors({
                                "job_run_id": $(this).attr('id').split('_')[1]
                                , "rc": $(this).attr('id').split('_')[2]
                            });
                        });
                        $(".flow-drilldown-link").click(function () {
                            navigate($(this).attr('id'));
                        });
                        $(".job-drilldown-link").click(function () {
                            navigate($(this).attr('id'));
                        });
                        $(".start-dts-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "START_END_TIME"
                            });
                        });
                        $(".end-dts-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "END_TIME"
                            });
                        });
                        $(".elapsed-time-link").click(function () {
                            plot({
                                "flow_run_id": $(this).attr('id').split('_')[1]
                                , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                , "flow_job_id": $(this).attr('id').split('_')[3]
                                , "plot_yvar": "ELAPSED_TIME"
                            });
                        });
                        $(".view-log-link").click(function () { viewLog($(this).attr('id').split('_')[1]); });
                        $(".dimon-status-progressbar").progressbar()
                            .each(function (i) {
                                var value = parseInt(this.id.split('_')[1]); // get value from id
                                if (isNaN(value)) {
                                    $(this).progressbar("option", "value", false); // no value found -> undeterminate
                                } else {
                                    var progressbarValue = Math.min(100, Math.max(5, value)); //value  min=5%, max=100%
                                    $(this).progressbar("value", progressbarValue);
                                    $(this).find('span').text(value + "%");
                                }
                                $(this).removeClass('ui-corner-all');
                            });
                        $(".trend-sparkline").each(function () {
                            $(this).sparkline('html', { width: '150px', fillColor: undefined })
                                .click(function (e) {
                                    plot({
                                        "flow_run_id": $(this).attr('id').split('_')[1]
                                        , "flow_run_seq_nr": $(this).attr('id').split('_')[2]
                                        , "flow_job_id": $(this).attr('id').split('_')[3]
                                        , "plot_yvar": "ELAPSED_TIME"
                                    });
                                });

                            setResults1Size();

                        });
                        $(":button:contains('Filter')").button("enable");
                    }
                }
                , error: function (XMLHttpRequest, textStatus, errorThrown) {
                    refreshJobsRunning = false;
                    handleAjaxError('refreshJobs', XMLHttpRequest, textStatus, errorThrown);
                }
            });
        }
    }

}//refreshJobs


function Steps(path) {

    clearInterval(interval);
    settings.currentView = 'Steps';
    updateFilterButtonLabel();
    updateSortButtonLabel();
    $("#btnFilter").button("disable");
    $("#btnSort").button("disable");
    $("#results1").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    refreshSteps(path);
    if (settings.autorefresh_interval != (autorefresh_intervals.length - 1)) {
        interval = setInterval('refreshSteps("' + path + '")', autorefresh_intervals[settings.autorefresh_interval] * 1000);
    }

}//Steps


function refreshSteps(path) {

    if ($("#results1").length) {

        if (!refreshStepsRunning) {

            refreshStepsRunning = true;
            $.ajax({
                url: settings.urlSPA
                , data: {
                    "_program": getSPName('dimonSteps')
                    , "job_run_id": path.split('_')[1]
                    , "_debug": _debug
                }
                , cache: false
                , timeout: ajaxTimeout
                , success: function (data) {

                    refreshStepsRunning = false;
                    handleAjaxSuccess();

                    // To prevent delayed output from SP, check if we're still in Steps view.
                    if (settings.currentView == 'Steps') {

                        $("#results1").html(data);

                        // move SAS-generated report title to #dimon-navbar
                        $("#dimon-navbar").html('<div id="navpath"></div><span id="btnNavbar"></span>');
                        $("#btnNavbar").html(svgDotsVertical).button().click(function () {
                            menuNavbar();
                        });
                        $("#results1 .systitleandfootercontainer").appendTo("#navpath");
                        $("#results1").find('br:first').remove();

                        // move SAS-generated footer to #dimon-footer
                        $("#dimon-footer").html("");
                        $("#results1 .reportfooter").appendTo("#dimon-footer");

                        $(".navpath-item").button().click(function () { navigate($(this).attr('id')); });
                        $(".view-log-link").click(function () {
                            viewLog($(this).attr('id').split('_')[1]
                                , $(this).attr('id').split('_')[2]);
                        });

                        $(":button:contains('Filter')").button("disable");
                        $(".dimon-info-message").addClass('ui-state-highlight');
                        $(".dimon-error-message").addClass('ui-state-error');

                        setResults1Size();

                    }
                }
                , error: function (XMLHttpRequest, textStatus, errorThrown) {
                    refreshStepsRunning = false;
                    handleAjaxError('refreshSteps', XMLHttpRequest, textStatus, errorThrown);
                }
            });
        }
    }

}//refreshSteps


function viewLog(job_run_id, anchor) {

    // get logfile filesize
    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: {
            "_program": getSPName('dimonGetLogfileSize')
            , "job_run_id": job_run_id
            , "_debug": _debug
        }
        , dataType: 'json'
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , success: function (data) {

            // chrome and firefox can handle much larger files than ie so maxsize is doubled for them
            if (data.filesize > settings.viewlog_maxfilesize) {
                var dialog = $('<div id="dialog-confirm" title="View SAS log file">'
                    + '<p><span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 20px 0;"></span>'
                    + 'The log file is large (' + data.filesize + ' bytes) and could take a long time'
                    + ' and a large amount of system resources to display in DI Monitor.'
                    + '<br><br>How do you want to view the file?</p>'
                ).appendTo('body');
                dialog.dialog({
                    // add a close listener to prevent adding multiple divs to the document
                    close: function (event, ui) {
                        // remove div with all data and events
                        dialog.remove();
                    },
                    resizable: false,
                    width: 600,
                    modal: true,
                    buttons: {
                        "View in DI Monitor": function () {
                            $(this).dialog("close");
                            viewLogInDimon(job_run_id, anchor);
                        }
                        , "Download": function () {
                            $(this).dialog("close");
                            window.location.href = settings.urlSPA + '?_program=' + getSPName('dimonViewLogExternally') + '&job_run_id=' + job_run_id;
                        }
                        , Cancel: function () {
                            $(this).dialog("close");
                        }
                    }
                });
                $(":button:contains('external')").focus(); // Set focus to the [View in external viewer] button
            } else {
                viewLogInDimon(job_run_id, anchor);
            }
        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('viewLog', XMLHttpRequest, textStatus, errorThrown);
        }
    });

}//viewLog


function viewLogInDimon(job_run_id, anchor) {

    dialog = $('<div id="dialogViewLog" style="display:none">'
        + '<div id="viewlogHeader">'
        + '<div id="viewlogTitle" class="l systemtitle SystemTitle"></div>'
        + '</div>'
        + '<div id="viewlogContent"></div>'
        + '</div>').appendTo('body');
    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'SAS Log for Job Run ID ' + job_run_id
        , width: $(window).width() * 0.95
        , height: $(window).height() * 0.95
        , modal: true
        , resize: function (event, ui) {
            setViewLogContentSize();
        }
        , buttons: {
            "Reload": function (event, ui) {
                $(":button:contains('Reload')").button("disable");
                getLog(job_run_id, 'max');
            }
            , "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });
    if (anchor == undefined) {
        anchor = 'l1';
    }
    getLog(job_run_id, anchor);

}//viewLogInDimon


function getLog(job_run_id, anchor) {

    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: {
            "_program": getSPName('dimonGetLogfileName')
            , "job_run_id": job_run_id
            , "_debug": _debug
        }
        , async: true
        , cache: false
        , dataType: 'json'
        , timeout: ajaxTimeout
        , success: function (data) {
            var s = '<div id="viewlogTitle-filename">File: ' + data.job_log_file + '</div>'
                + '<span id="viewlogOptionsButton" title="Options"></span>'
                ;
            //$("#viewlogTitle").html("File: " + data.job_log_file);
            $("#viewlogTitle").html(s);
            $("#viewlogOptionsButton").html(svgDotsVertical).button().click(function () {
                viewlogOptionsMenu(job_run_id);
            });
        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('getLog', XMLHttpRequest, textStatus, errorThrown);
        }
    });

    $("#viewlogContent").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: {
            "_program": getSPName('dimonViewLog')
            , "job_run_id": job_run_id
            , "_debug": _debug
        }
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , success: function (data) {
            $("#viewlogContent").html(data);
            $("#viewlogContent").focus();// IE7 Standard document mode hack to fix scrolling with absolute div positioning
            if (anchor) {
                $('#viewlogContent').animate({
                    scrollTop: $('#' + anchor).offset().top - $('#l1').offset().top
                }, 300);
            }
            $(":button:contains('Reload')").button("enable");
            $(":button:contains('Close')").focus(); // Set focus to the [Close] button
            $(".dimon-info-message").addClass('ui-state-highlight');
            $(".dimon-error-message").addClass('ui-state-error');
            setViewLogContentSize();
        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('getLog', XMLHttpRequest, textStatus, errorThrown);
        }
    });

}//getLog


function viewlogOptionsMenu(job_run_id) {

    $('#viewlogOptionsMenu').remove(); // remove filter in case it already exists
    $('.ui-tooltip').fadeOut(300, function () { $(this).remove(); }); // fade-out and remove tooltip
    var s = '<ul class="dropdown-menu">'
        + '<li class="li-dropdown-item" id="viewlogDownload">'
        + '<div><span class="text-dropdown-item ui-widget">&nbsp;&nbsp;Download</span></div><br>'
        + '</li>'
        + '</ul>';
    button = $("#viewlogOptionsButton");
    var menuWidth = 160;
    var buttonPosition = button.position();
    var menuLeft = buttonPosition.left + button.width() - menuWidth;
    var menuTop = buttonPosition.top + button.height() + 8;
    $("#viewlogOptionsMenu").remove(); // remove menu in case it already exists
    var viewlogOptionsMenu = $('<div id="viewlogOptionsMenu" style="display:block;z-index:1001;width:' + menuWidth + 'px;" class="dropdown-menu"></div>').appendTo('body');
    $("#viewlogOptionsMenu").html(s)
        .position({ my: "right top", at: "center+10px bottom", of: button, collision: "fit" });
    $("#viewlogDownload").click(function () {
        $("#viewlogOptionsMenu").remove();
        window.location.href = settings.urlSPA + '?_program=' + getSPName('dimonViewLogExternally') + '&job_run_id=' + job_run_id;;
    });
    $("#viewlogOptionsMenu").show();

}//viewlogOptionsMenu


function plot(parms) {

    parms.div = "plot";
    var plot_histdays = (Cookies.get('dimonPlotHistDays') == null ? 90 : Cookies.get('dimonPlotHistDays'));
    var plot_ci = (Cookies.get('dimonPlotCI') == null ? 95 : Cookies.get('dimonPlotCI'));
    var plot_showzero = (Cookies.get('dimonPlotShowZero') == null ? 'yes' : Cookies.get('dimonPlotShowZero'));
    //var plot_hideoutliers = ( Cookies.get('dimonPlotHideOutliers') == null ?  'no' : Cookies.get('dimonPlotHideOutliers') );
    var plot_hideoutliers = 'no';

    var dialog = $('<div id="dialogHistoryPlot" style="display:none">'
        + '<div id="plotControls" class="ui-widget">'
        + '<form action="#">'
        + '<fieldset>'
        + '<label for="combobox-numdays">Number of days</label>'
        + '<select name="combobox-numdays" id="combobox-numdays" class="dimon-combobox">'
        + '<option value="1"' + (plot_histdays == '1' ? ' selected="selected"' : '') + '>1 day</option>'
        + '<option value="7"' + (plot_histdays == '7' ? ' selected="selected"' : '') + '>7 days</option>'
        + '<option value="14"' + (plot_histdays == '14' ? ' selected="selected"' : '') + '>14 days</option>'
        + '<option value="30"' + (plot_histdays == '30' ? ' selected="selected"' : '') + '>30 days</option>'
        + '<option value="60"' + (plot_histdays == '60' ? ' selected="selected"' : '') + '>60 days</option>'
        + '<option value="90"' + (plot_histdays == '90' ? ' selected="selected"' : '') + '>90 days</option>'
        + '<option value="180"' + (plot_histdays == '180' ? ' selected="selected"' : '') + '>180 days</option>'
        + '<option value="360"' + (plot_histdays == '360' ? ' selected="selected"' : '') + '>360 days</option>'
        + '<option value="720"' + (plot_histdays == '720' ? ' selected="selected"' : '') + '>720 days</option>'
        + '</select>'
        + '<label for="combobox-ci">Confidence interval</label>'
        + '<select name="combobox-ci" id="combobox-ci" class="dimon-combobox">'
        + '<option value="90"' + (plot_ci == '90' ? ' selected="selected"' : '') + '>90%</option>'
        + '<option value="95"' + (plot_ci == '95' ? ' selected="selected"' : '') + '>95%</option>'
        + '<option value="99"' + (plot_ci == '99' ? ' selected="selected"' : '') + '>99%</option>'
        + '</select>'
        + '<label for="checkbox-showzero">Show zero on vertical axis</label>'
        + '<input id="checkbox-showzero" class="dimon-checkbox showzero" type="checkbox"' + (plot_showzero == 'yes' ? ' checked="checked"' : '') + '>'
        + '<label for="checkbox-hideoutliers">Hide outliers</label>'
        + '<input id="checkbox-hideoutliers" class="dimon-checkbox hideoutliers" type="checkbox"' + (plot_hideoutliers == 'yes' ? ' checked="checked"' : '') + '>'
        + '<fieldset>'
        + '</div>'
        + '<div id="plot">'
        + '<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />'
        + '</div>'
        + '</div>').appendTo('body');
    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'Elapsed Time History'
        , width: 1250
        , height: 640
        , modal: true
        , buttons: {
            "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });
    $(".dimon-combobox").selectmenu({
        change: function (event, data) {
            Cookies.set('dimonPlotHistDays', $("#combobox-numdays").val(), { expires: 365 });
            Cookies.set('dimonPlotCI', $("#combobox-ci").val(), { expires: 365 });
            createPlot(parms);
        }
    });
    $("#checkbox-showzero").button()
        .click(function () {
            Cookies.set('dimonPlotShowZero', ($("#checkbox-showzero").is(':checked') ? "yes" : "no"), { expires: 365 });
            createPlot(parms);
        });
    $("#checkbox-hideoutliers").button()
        .click(function () {
            Cookies.set('dimonPlotHideOutliers', ($("#checkbox-hideoutliers").is(':checked') ? "yes" : "no"), { expires: 365 });
            createPlot(parms);
        });

    // load remote content
    createPlot(parms);
    $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//historyPlot


function createPlot(parms) {

    $('#' + parms.div).html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: $.extend({
            "_program": getSPName("dimonPlot")
            , "plot_histdays": $("#combobox-numdays").val()
            , "plot_ci": $("#combobox-ci").val()
            , "plot_showzero": ($("#checkbox-showzero").is(':checked') ? "yes" : "no")
            , "plot_hideoutliers": ($("#checkbox-hideoutliers").is(':checked') ? "yes" : "no")
            , "plot_xpixels": "900"
            , "plot_ypixels": "400"
            , "_gopt_device": 'png'
            , "_debug": _debug
        }
            , parms)
        , cache: false
        , timeout: ajaxTimeout
        , success: function (data) {
            $('#' + parms.div).html(data);
        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('createPlot', XMLHttpRequest, textStatus, errorThrown);
        }
    });

}//createHistoryPlot


function viewNotesWarningsErrors(parms) {

    var dialog = $('<div id="dialogNotesWarningsErrors" style="display:none"></div>').appendTo('body');
    var s = '';
    s += '<div id="menubarNotesWarningsErrors">';
    s += '<div id="titleNotesWarningsErrors" class="l systemtitle SystemTitle"><span>Notes, Warnings and/or Errors for '
        + (parms.flow_run_id !== undefined ? 'Flow Run ID ' + parms.flow_run_id + ' / ' + parms.flow_run_seq_nr
            : 'Job Run ID ' + parms.job_run_id)
        + '</span></div>'
        ;
    var rc = 2;
    if (parms.rc !== undefined) {
        rc = parms.rc;
    }
    s += '<div id="buttonbarNotesWarningsErrors">';
    s += '<input type="checkbox" id="flowDetailsNotes" ' + (rc == 0 ? 'checked="checked"' : "") + ' /><label for="flowDetailsNotes">Notes</label>';
    s += '<input type="checkbox" id="flowDetailsWarnings" ' + (rc == 1 ? 'checked="checked"' : "") + ' /><label for="flowDetailsWarnings">Warnings</label>';
    s += '<input type="checkbox" id="flowDetailsErrors" ' + (rc >= 2 ? 'checked="checked"' : "") + ' /><label for="flowDetailsErrors">Errors</label>';
    s += '</div>';
    s += '</div>';
    s += '<div id="sasresultNotesWarningsErrors"></div>';
    $("#dialogNotesWarningsErrors").html(s);
    $("div#buttonbarNotesWarningsErrors").buttonset();
    $("div#buttonbarNotesWarningsErrors :checkbox").click(function (e) {
        loadNotesWarningsErrorsContent(dialog, parms);
    });
    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'Notes, Warnings, Errors'
        , width: $(window).width() * 0.95
        , height: $(window).height() * 0.95
        , modal: true
        , buttons: {
            "Close": function (event, ui) {
                $(this).dialog('close');
            }
        }
    });

    loadNotesWarningsErrorsContent(dialog, parms);
    $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//viewNotesWarningsErrors


function loadNotesWarningsErrorsContent(dialog, parms) {

    // load remote content flowDetails
    $("#sasresultNotesWarningsErrors").html('<img src="' + settings.imgroot + '/dimon-ajax-loader.gif" />');
    $.ajax({
        type: "GET"
        , url: settings.urlSPA
        , data: $.extend({
            "_program": getSPName('dimonViewNotesWarningsErrors')
            , "showNotes": ($('#flowDetailsNotes').is(':checked') ? "Y" : "N")
            , "showWarnings": ($('#flowDetailsWarnings').is(':checked') ? "Y" : "N")
            , "showErrors": ($('#flowDetailsErrors').is(':checked') ? "Y" : "N")
            , "_debug": _debug
        }
            , parms)
        , async: true
        , cache: false
        , timeout: ajaxTimeout
        , success: function (data) {
            $("#sasresultNotesWarningsErrors").html(data);
            $(".view-log-links").click(function () {
                viewLog($(this).attr('id').split('_')[1]
                    , $(this).attr('id').split('_')[2]);
            });
            $(":button:contains('Close')").focus(); // Set focus to the [Close] button
            $(".dimon-info-message").addClass('ui-state-highlight');
        }
        , error: function (XMLHttpRequest, textStatus, errorThrown) {
            handleAjaxError('loadNotesWarningsErrorsContent', XMLHttpRequest, textStatus, errorThrown);
        }
    });

}//loadNotesWarningsErrorsContent


// This function is for the Stored Processes Show SAS Log and Hide SAS Log functionality
// which for some reason doesn't work with div's, so we copy-and-pasted it to here
var SASLOGisVisible = false;
function toggleLOG() {
    container = document.getElementById("SASLOGContainer");
    content = document.getElementById("SASLOG");
    button = document.getElementById("LOGbutton");
    if (SASLOGisVisible === false) {
        container.innerHTML = content.innerHTML;
        button.value = "Hide SAS Log";
        SASLOGisVisible = true;
    } else {
        container.innerHTML = "";
        button.value = "Show SAS Log";
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


function handleAjaxError(spName, XMLHttpRequest, textStatus, errorThrown) {

    if (textStatus == "timeout") {
        ajaxTimedOut = true;
        $('<div id="dimon-statusmessage" class="error">Server connection failed (time-out)</div>').appendTo('body').delay(5000).fadeOut(function () { $(this).remove(); });
    } else if (XMLHttpRequest.readyState == 0 || XMLHttpRequest.status == 0) {
        return;  // it's not really an error
    } else {
        clearInterval(interval); // stop autorefreshing
        var r = confirm(spName
            + '\n\nError ' + XMLHttpRequest.status + ' : ' + textStatus + " (" + errorThrown + ")"
            + '\n\nClick OK to view the error response text, click Cancel to return.');
        if (r == true) {
            showAjaxError(XMLHttpRequest.responseText);
        } else {
            refresh(); // continue
        }
    }

}//handleAjaxError


function showAjaxError(msg) {

    var dialog = $('<div id="dialogSasError"></div>').appendTo("body");
    dialog.dialog({    // add a close listener to prevent adding multiple divs to the document
        close: function (event, ui) {
            // remove div with all data and events
            dialog.remove();
        }
        , title: 'SAS Error'
        , width: $(window).width() * 0.75
        , height: $(window).height() * 0.95
        , modal: true
        , buttons: {
            "Close": function (event, ui) {
                $(this).dialog('close');
                refresh(); // continue
            }
        }
    });
    $("#dialogSasError").html(msg);
    $(":button:contains('Close')").focus(); // Set focus to the [Close] button

}//showAjaxError


function handleAjaxSuccess() {

    if (ajaxTimedOut == true) {
        $('<div id="dimon-statusmessage" class="info">  We\'re back.  </div>').appendTo('body').delay(5000).fadeOut(function () { $(this).remove(); });
        ajaxTimedOut = false;
    }

}//handleAjaxSuccess

function disableButton(btn) {
    btn.prop('disabled', true).addClass("ui-state-disabled");
}

function enableButton(btn) {
    btn.prop('disabled', false).removeClass("ui-state-disabled");
}
