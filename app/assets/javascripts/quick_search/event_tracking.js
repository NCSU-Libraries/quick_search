var quickSearchEventTracking = (function () {

    // Configs

    var config = {
        clickTrackingContainer: '.quicksearch-ga-click-tracking',
        serveTrackingContainer: '.quicksearch-ga-serve-tracking',
        testingContainer: '#quicksearch-ga-debug',
        seeAllClass: 'see-all-results',
        categoryDataAttribute: 'quicksearch-ga-category',
        actionDataAttribute: 'quicksearch-ga-action',
        labelDataAttribute: 'quicksearch-ga-label',
        logQueryDataAttribute: 'quicksearch-ga-query'
    }

    // Public Methods

    function listenForClicks () {
        $(document).on('click', config.clickTrackingContainer + ' a', function(e) {
            var eventValuesDefined = eventValues($(this));
            var link = $(this)[0];

            // This ensures that ctrl and cmd click to open
            // link in a new window/tab continues to function.
            // No need to preventDefault in this case
            // because the original page remains.
            if (e.metaKey || e.ctrlKey) {
                sendEventData(eventValuesDefined, '');
                return;
            } else {
                sendEventData(eventValuesDefined, link);
                e.preventDefault();
            }

            // In case the hitCallback isn't triggered soon enough we ensure the link is followed
            // after this timeout in any case.
            setTimeout(function() {
              document.location.href = link.href;
            }, 200);
        });
    }

    function listenForServesOnPageChange () {
        $(document).ready(function() {
            serveTrackingDivs = $(config.serveTrackingContainer).get();
            $.map(serveTrackingDivs, function(val) {
                checkForServes(val);
            });
        });
    }

    function checkForServes(val) {
        var link = $(val).find('a');
        var eventValuesDefined = eventValues(link);
        eventValuesDefined.action_type = 'serve';
        sendEventData(eventValuesDefined, '');
    }



    // Private Methods

    function eventValues (link) {
        var link = link;
        var ga_event = {};
        ga_event.category = eventCategory(link);
        ga_event.action = eventAction(link);
        ga_event.label = eventLabel(link);
	ga_event.action_type = 'click';
        return ga_event;
    }

    function eventCategory (link) {
        // FIXME: There may be a better way to get the action from the parent.
        var category;
        if (link.data(config.categoryDataAttribute)) {
            category = link.data(config.categoryDataAttribute);
        } else if (link[0].id.length > 0) {
            category = link[0].id;
        } else {
            category = link.parents('[id]:first')[0].id;
        }
        return category;
    }

    function eventAction (link) {
        var action;
        if (link.data(config.actionDataAttribute)) {
            action = link.data(config.actionDataAttribute);
        } else if (link.hasClass(config.seeAllClass)) {
            action = 'see-all-results';
        } else if (link.parent('h1,h2').length > 0) {
            action = 'heading';
        } else {
            index = link.parents('li').index()
            result = index + 1
            action = 'result-' + result;
        }
        return action
    }

    function eventLabel (link) {
        var label;
        if (link.data(config.labelDataAttribute)) {
            label = link.data(config.labelDataAttribute);
        } else if (link.parents('body').data(config.logQueryDataAttribute)){
            label = link.parents('body').data(config.logQueryDataAttribute);
        } else {
            label = link[0].href;
        } 
        return label;
    }

    function sendEventData (eventValues, link) {
        var railsEnv = window.QuickSearchConfig ? window.QuickSearchConfig.railsEnv : 'production';
        
        if (railsEnv === 'development') {
            console.log('click_tracking', [eventValues.category, eventValues.action, eventValues.label]);
            $.when(logEventToDatabase(eventValues)).then(function () {
                if (link !== '') {
                    //document.location.href = link;
                }
            });
        } else if (railsEnv === 'production' || railsEnv === 'staging') {
            $.when(logEventToDatabase(eventValues)).then(function () {
                sendDataToGoogleAnalytics(eventValues, link)
            });
        } else {
            appendTestingData(eventValues);
        }
    }

    function appendTestingData (eventValues) {
        var debugBlock = $(config.testingContainer);
        var debugList = $(config.testingContainer + ' ol');
        debugList.empty();
        $.map (eventValues, function(val) {
            debugList.append('<li>' + val + '</li>');
        });
        debugBlock.show();
    }

    function sendDataToGoogleAnalytics (eventValues, link) {
        
        // Universal Analytics

        var category = eventValues.action_type == 'serve' ? eventValues.category + '-serve' : eventValues.category;


         ga('send', {
             hitType: 'event',
             eventCategory: category,
             eventAction: eventValues.action,
             eventLabel: eventValues.label,
             hitCallback: function () {
                 if (link !== '') {
                     document.location = link;
                 }
             }
         });
        
    }

    function logEventToDatabase(eventValues) {

        url = window.QuickSearchRoutes.logEvent;

        return $.ajax({
            url: url,
            data: {
                category: eventValues.category,
                event_action: eventValues.action,
                label: eventValues.label,
                action_type: eventValues.action_type
            }
        });
    }

    function checkForSearch() {
        if ($('body').data(config.logQueryDataAttribute)) {
            var query = $('body').data(config.logQueryDataAttribute);
            if (query != '') {
                searchValuesDefined = searchValues(query);
                logSearchToDatabase(searchValuesDefined);
            }
        }
    }

    function searchValues (query) {
        var link = link;
        var ga_search = {};
        ga_search.query = query;
        ga_search.page = searchPage();
        return ga_search;
    }

    function searchPage() {
        var pathname = window.location.pathname;

        // Get the pathname relative to the application root
        var relativeUrlRoot = window.QuickSearchConfig ? (window.QuickSearchConfig.relativeUrlRoot || '') : '';
        return pathname.replace(relativeUrlRoot, "");
    }

    function logSearchToDatabase(searchValues) {
        console.log(searchValues);
        url = window.QuickSearchRoutes.logSearch;

        return $.ajax({
            url: url,
            data: {
                query: searchValues.query,
                page: searchValues.page
            }
        });
    }


    return {

        // Expose Public Methods
        
        listenForClicks: listenForClicks,
        listenForServesOnPageChange: listenForServesOnPageChange,
        checkForServes: checkForServes,
        checkForSearch: checkForSearch

    };
 
})();

$( document ).ready(function() {
    quickSearchEventTracking.checkForSearch();
    if ($("body").hasClass("search-index")) {
        quickSearchEventTracking.listenForClicks();
        quickSearchEventTracking.listenForServesOnPageChange();
    }
});