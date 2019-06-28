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
    $('.read-more').click(function (e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        $(e.target).parent().hide();
        $(e.target).parent().siblings('.description-full').show();
    });
    $('.read-less').click(function (e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        $(e.target).parent().hide();
        $(e.target).parent().siblings('.description-truncated').show();
    });

});
