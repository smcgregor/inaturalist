// Like the name says, this is collection of taxon selectors. 
// simpleTaxonSelector just takes a text input and uses it as a search field
// to find taxa, filling in a following taxon_id field if one exists.
(function($){
  $.fn.simpleTaxonSelector = function(options) {
    var options = $.extend({}, $.fn.simpleTaxonSelector.defaults, options);
    options.inputWidth = $(this).outerWidth();
    options.inputHeight = $(this).outerHeight();
    
    var instances = [];
    this.each(function() {
      instances.push(setup(this, options));
    });
    return instances;
  }; /* end $.fn.simpleTaxonSelector */
  
  /*
   * Setup a single input as a simpleTaxonSelector.
   */
  function setup(input, options) {
    // Wrap the form field
    $(input).wrap($('<div class="simpleTaxonSelector"></div>'));
    var wrapper = $(input).parent();
    $(wrapper).css({
      position: 'relative',
      width: options.inputWidth,
      'margin-bottom': $(input).css('margin-bottom')
    });
    
    var taxon_id = getTaxonID(wrapper, options);
    
    // Insert the taxon image
    var imageURL = '/images/iconic_taxa/unknown-32px.png';
    if (typeof($(taxon_id).attr('rel')) != 'undefined' && $(taxon_id).attr('rel') != '') {
      imageURL = $(taxon_id).attr('rel');
    }
    var image = $('<img src="'+imageURL+'" class="simpleTaxonSelectorImage"/>');
    $(image).css({
      width: '32px',
      float: 'left',
      'margin-right': '10px',
      'margin-top': '3px'
    });
    $(wrapper).prepend(image);

    // Insert the lookup button
    var button = $('<input type="button" class="button" />');
    
    $(button).css({
      margin: 0,
      float: 'left'
    }).val(options.buttonText);
    $(button).height(options.inputHeight);
    $(wrapper).append(button);
    
    // Resize & style the input
    $(input).width(options.inputWidth - $(button).outerWidth() - 67);
    $(input).css({
      float: 'left',
      'margin-right': '10px',
      'margin-bottom': '3px'
    });

    // Bind the lookup button
    $(button).click(function() {
      // Catch exceptions to ensure false return and precent form submission
      try {
        $.fn.simpleTaxonSelector.lookup(wrapper, options);
      }
      catch (e) {
        // console.log(e);
      }
      return false;
    });

    // Bind enter/return within the form field
    $(input).keypress(function(e) {
      if (e.which == 13) {
        // Catch exceptions to ensure false return and precent form submission
        try {
          $.fn.simpleTaxonSelector.lookup(wrapper, options);
        }
        catch (e) {
          // console.log(e);
        }
        return false;
      };
    });
    
    // Clear the taxon on blur if the name is blank
    $(input).blur(function(e) {
      if ($.trim($(this).val()) == '') {
        $.fn.simpleTaxonSelector.unSelectTaxon(wrapper, options);
      };
    });

    // Insert the status
    var status = $('<div class="status">Type Unknown</div>');
    $(status).css(
      $.extend(
        $.fn.simpleTaxonSelector.styles.statuses['default'],
        $.fn.simpleTaxonSelector.styles.statuses.unmatched
      )
    );
    $(wrapper).append(status);
    
    // Recognize previously selected taxon, lookup unassociated name
    if ($(input).val() != '' || $(taxon_id).val() != '') {
      // if both are set, lookup the taxon
      if ($(taxon_id).val() != '') {
        // If the taxon_id input has an alt set, use that as the matched 
        // status.  Otherwise, look it up.
        if ($(taxon_id).attr('alt') != '') {
          $.fn.simpleTaxonSelector.setStatus(wrapper, 'matched', 
            $(taxon_id).attr('alt'));
        } else {
          $.fn.simpleTaxonSelector.setStatus(wrapper, 'loading', 'Loading...');
          jQuery.getJSON('/taxa/'+$(taxon_id).val()+'.json', function(taxon) {
            // console.log("taxon: ", taxon);
            if (typeof(taxon.common_name) != 'undefined' && taxon.common_name != null) {
              taxon.common_name.taxon = taxon;
              // console.log("formating the common name: ", taxon.common_name);
              var formattedName = $.fn.simpleTaxonSelector.taxonNameToS(taxon.common_name, {taxon: taxon});
            } else {
              for (var i = taxon.taxon_names.length - 1; i >= 0; i--){
                if (taxon.taxon_names[i].name == taxon.name) {
                  // console.log("formatting a taxon name: ", taxon.taxon_names[i]);
                  taxon.taxon_names[i].taxon = taxon
                  var formattedName = $.fn.simpleTaxonSelector.taxonNameToS(
                    taxon.taxon_names[i], {taxon: taxon});
                  break;
                };
              };
            }
            if (typeof(formattedName) == 'undefined') {
              if (taxon.taxon_names.length == 0) {
                // console.log("just making formatting the taxon");
                var formattedName = $.fn.simpleTaxonSelector.taxonToS(taxon);
              } else {
                // console.log("formatting the first taxon name");
                taxon.taxon_names[0].taxon = taxon
                var formattedName = $.fn.simpleTaxonSelector.taxonNameToS(
                  taxon.taxon_names[0], {taxon: taxon});
              }
            };
            $.fn.simpleTaxonSelector.setStatus(wrapper, 'matched', 
              formattedName);
            if ($(input).val() == '') {
              $(input).val(taxon.name);
            };
          }); 
        }
      } else { // if only the guess is set, look that up
        $.fn.simpleTaxonSelector.lookup(wrapper, options);
      }
    };
  } /* end setup() */
  
  /*
   ************************* PRIVATE METHODS *************************
   */
  function handleTaxa(wrapper, taxa, options) {
    var options = $.extend({}, options);
    var input = $(wrapper).find('input[type=text]:first');
    var q = $(input).attr('value');
  
    // If there were no results, give notice and provide external lookup
    // options
    if (taxa.length == 0) {
      var status = $('<span>No results for "' + q + '".<br/></span>');
      $.fn.simpleTaxonSelector.setStatus(wrapper, 'unmatched', status);
    }
  
    // If there's only one result and it's an exact match, select the taxon
    else if (taxa.length == 1 && 
             (taxa[0].name.toLowerCase() == q.toLowerCase() ||
              (typeof(taxa[0].default_name) != 'undefined' && 
                taxa[0].default_name.name.toLowerCase() == q.toLowerCase()))) {
      $.fn.simpleTaxonSelector.selectTaxon(wrapper, taxa[0], options);
    }
  
    // Otherwise, display each as an selection option
    else {
      var message = $('<span>Did you mean</span>');
      var list = $('<ul class="matches"></ul>').css({'margin-bottom': '3px'});
      $(taxa).each(function(i, taxon) {
        list.append(
          $('<li></li>').append(
            $('<a href="#"></a>').append(
              $.fn.simpleTaxonSelector.taxonNameToS(taxon.default_name, {taxon: taxon})
            ).click(function() {
              $.fn.simpleTaxonSelector.selectTaxon(wrapper, taxon, options);
              return false;
            })
          )
        );
      });
      message.append(list);
  
      $.fn.simpleTaxonSelector.setStatus(wrapper, 'unmatched', message);
    }
  } // end handleNames
  
  function getTaxonID(wrapper, options) {
    var options = $.extend({}, options);
    if (typeof(options.taxonIDField) != 'undefined') {
      return $(options.taxonIDField);
    };
    var taxon_id = $(wrapper).next('input[name="taxon_id"]:first');
    if ($(taxon_id).length == 0) {
      taxon_id = $(wrapper).next('input[name*="[taxon_id]"]:first');
    };
    return taxon_id;
  }
  
  
  /*
   ************************* PUBLIC METHODS *************************
   */
  
  /*
   * Set the status for a taxonSelector.
   */
  $.fn.simpleTaxonSelector.setStatus = function(wrapper, statusType, message) {
    var status = $(wrapper).find('.status:first');
    $.each($.fn.simpleTaxonSelector.styles.statuses, function(statusKey) {
      $(status).removeClass(statusKey);
    });
    
    $(status).addClass(statusType);
    $(status).css($.fn.simpleTaxonSelector.styles.statuses[statusType]);
    
    if (typeof(message) != 'undefined') {
      $(status).empty();
      $(status).append(message);
    };
  };
  
  $.fn.simpleTaxonSelector.lookup = function(wrapper, options) {
    var options = $.extend({}, options);
    var input = $(wrapper).find('input[type=text]:first');
    var q = $(input).attr('value');
    var url = '/taxa/search.json?per_page=10&q='+q;
    if (options.includeExternal) {
      url += '&include_external=1';
    };
    if (options.forceExternal) {
      url += '&force_external=1';
    };
    
    // If blank, unset
    if (q == '') {
      $.fn.simpleTaxonSelector.unSelectTaxon(wrapper, options);
      return false;
    };
    
    // Get the JSON
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      beforeSend: function(XMLHttpRequest) {
        $.fn.simpleTaxonSelector.setStatus(wrapper, 'loading', 'Loading...');
      },
      success: function(data) {
        if (data.status) {
          $.fn.simpleTaxonSelector.setStatus(wrapper, 'error', data.status);
        };
        handleTaxa(wrapper, data, options);
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        // console.log(errorThrown);
      }
    });
  };
  
  $.fn.simpleTaxonSelector.unSelectTaxon = function(wrapper, options) {
    var input = $(wrapper).find('input[type=text]:first');
    var taxon_id = getTaxonID(wrapper, options);
    var image = $(wrapper).find('.simpleTaxonSelectorImage:first');
    
    // Set the taxon_id
    $(taxon_id).val('');
    $(input).val('');

    // Set the status
    $.fn.simpleTaxonSelector.setStatus(wrapper, 'unmatched', 
      'Species Unknown');
    
    // Set the image
    $(image).attr('src', '/images/iconic_taxa/unknown-32px.png')
    
    // Fire afterUnselect callback
    if (typeof(options) != 'undefined' && typeof(options.afterUnselect) == 'function') {
      options.afterUnselect(wrapper, name, options);
    };
  };
  
  $.fn.simpleTaxonSelector.selectTaxon = function(wrapper, taxon, options) {
    var options = $.extend({}, options);
    
    // Fire beforeSelect callback
    if (typeof(options.beforeSelect) == 'function') {
      if (options.beforeSelect(wrapper, taxon, options) == false) {
        return false;
      };
    };
    
    var input = $(wrapper).find('input[type=text]:first');
    var taxon_id = getTaxonID(wrapper, options);

    // Set the taxon_id
    $(taxon_id).val(taxon.id);
    if (typeof(options.selectedName) != 'undefined') {
      $(input).val(options.selectedName);
    } else if (typeof(taxon.default_name) != 'undefined') {
      $(input).val(taxon.default_name.name);
    } else {
      $(input).val(taxon.name);
    }

    // Set the status
    if (typeof(taxon.common_name) != 'undefined' && taxon.common_name != null) {
      var message = $.fn.simpleTaxonSelector.taxonNameToS(taxon.common_name, {taxon: taxon});
    } else if (typeof(taxon.default_name) != 'undefined' && taxon.default_name != null) {
      var message = $.fn.simpleTaxonSelector.taxonNameToS(taxon.default_name, {taxon: taxon});
    } else {
      var message = $.fn.simpleTaxonSelector.taxonToS(taxon);
    }
    $.fn.simpleTaxonSelector.setStatus(wrapper, 'matched', message);
    
    // Update the image
    if (typeof(taxon.image_url) != 'undefined') {
      $(wrapper).find('.simpleTaxonSelectorImage').attr('src', taxon.image_url);
    };
    
    // Fire afterSelect callback
    if (typeof(options.afterSelect) == 'function') {
      options.afterSelect(wrapper, taxon, options);
    };
  };
  
  $.fn.simpleTaxonSelector.taxonNameToS = function(name, options) {
    var options = $.extend({}, options);
    var taxon = typeof(name.taxon) == 'undefined' ? options.taxon : name.taxon
    var formatted = $('<span class="taxon"></span>');
    if (typeof(taxon.iconic_taxon) != 'undefined') {
      formatted.addClass(taxon.iconic_taxon.name);
    } else {
      formatted.addClass('Unknown');
    }
    var formattedSciName = $.fn.simpleTaxonSelector.taxonToS(taxon);
    if (name.lexicon == 'scientific names') {
      if (name.is_valid) {
        $(formatted).append(formattedSciName);
      } else {
        $(formatted).append(name['name'] + ' (=');
        $(formatted).append(formattedSciName);
        $(formatted).append(')');
      };
    }
    else {
      $(formatted).append(name['name'] + ' (');
      $(formatted).append(formattedSciName);
      $(formatted).append(')');
    }
    return $(formatted).get(0);
  };
  
  $.fn.simpleTaxonSelector.taxonToS = function(taxon) {
    var formatted = $('<span></span>').append(taxon.name);
    return $(formatted).get(0);
  };
  
  $.fn.simpleTaxonSelector.styles = {};
  $.fn.simpleTaxonSelector.styles.statuses = {};
  $.fn.simpleTaxonSelector.styles.statuses['default'] = {
    'padding': '0 0 0 20px',
    margin: 0,
    border: 0,
    clear: 'both'
  };
  
  $.fn.simpleTaxonSelector.styles.statuses.matched = $.extend({}, 
    $.fn.simpleTaxonSelector.styles.statuses['default'], {
      color: 'green',
      background: "transparent none",
      padding: 0
  });
  
  $.fn.simpleTaxonSelector.styles.statuses.unmatched = $.extend({}, 
    $.fn.simpleTaxonSelector.styles.statuses['default'], {
      color: '#888',
      background: 'url(/images/logo-grey-15px.png) 0 3px no-repeat'
  });
  
  $.fn.simpleTaxonSelector.styles.statuses.error = $.extend({}, 
    $.fn.simpleTaxonSelector.styles.statuses['default'], {
      color: 'DeepPink',
      background: "url('/images/logo-DeepPink-15px-error.png') 0 3px no-repeat"
  });
  
  $.fn.simpleTaxonSelector.styles.statuses.loading = $.extend({}, 
    $.fn.simpleTaxonSelector.styles.statuses['default'], {
      color: '#888',
      background: 'url(/images/spinner-small.gif) 0 3px no-repeat'
  });
  
  $.fn.simpleTaxonSelector.defaults = {
    buttonText: 'Lookup',
    includeSearchExternal: true
  };
})
(jQuery);
