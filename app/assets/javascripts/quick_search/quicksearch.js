$(document).ready(function() {

    // Fade out best bet highlight after 3 seconds
    if (window.innerWidth > 640) {
        $('.highlight').delay( 6000 ).fadeOut( 500 );
    } else {
        $('.highlight').remove();
    }

    // remove some generic library website template content from DOM
    $('#utility-search').remove();
    $('#search-toggle').remove();

});

// Handle read more/read less toggle - MUST be registered before result-types handler
$(document).on('click', '.read-more, .read-less', function(e) {
    e.preventDefault();
    e.stopImmediatePropagation(); // Stop all other handlers from executing
    const container = $(this).closest('.description');
    const trunc = container.find('.description-truncated');
    const full = container.find('.description-full');
    
    // Toggle Visibility
    if (trunc.is(':visible')) {
        trunc.hide();
        full.show();
        // Move focus to the "Read less" button for keyboard users
        setTimeout(function() {
            full.find('.read-less').focus();
        }, 50);
    } else {
        full.hide();
        trunc.show();
        // Move focus back to "Read more" for keyboard users
        setTimeout(function() {
            trunc.find('.read-more').focus();
        }, 50);
    }
});

//  This handles the highlighting of modules when a result types quide link is clicked
$(document).on('click', '.result-types a', function () {
    // Grab the hash value
    var hash = this.hash.substr(1);

    // Remove any active highlight
    $('.result-types-highlight').remove();

    // Add the highlight
    $('#' + hash + ' h2').prepend('<span class="result-types-highlight"><i class="fa fa-angle-double-right highlight"></i>&nbsp;</span>');

    // Fade it away and then remove it.
    $('#' + hash + ' .highlight').delay( 3000 ).animate({backgroundColor: 'transparent'}, 500 );
    setTimeout(function() {
        $('#' + hash + ' .result-types-highlight').remove();
    }, 3550);
});

$
