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

$(document).ready(function () {
    $('.read-more, .read-less').on('click', function(e) {
        e.preventDefault();
        const container = $(this).closest('.description-container');
        const trunc = container.find('.description-truncated');
        const full = container.find('.description-full');
        
        // Toggle Visibility
        trunc.toggle();
        full.toggle();

        // Handle Focus for Keyboard Users
        if (full.is(':visible')) {
            full.find('.read-less').focus(); // Move focus to the "Read less" button
        } else {
            trunc.find('.read-more').focus(); // Move focus back to "Read more"
        }
    });
});

$
