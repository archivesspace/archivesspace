/**
 * Accordion module.
 * @module foundation.accordion
 * @requires foundation.util.keyboard
 * @requires foundation.util.motion
 */
!function($, Foundation) {
  'use strict';

  /**
   * Creates a new instance of an accordion.
   * @class
   * @fires Accordion#init
   * @param {jQuery} element - jQuery object to make into an accordion.
   */
  function AccordionTable(element, options){
    this.$element = element;
    this.options = $.extend({}, AccordionTable.defaults, this.$element.data(), options);

    this._init();

    Foundation.registerPlugin(this, 'AccordionTable');
    Foundation.Keyboard.register('AccordionTable', {
      'ENTER': 'toggle',
      'SPACE': 'toggle',
      'ARROW_DOWN': 'next',
      'ARROW_UP': 'previous'
    });
  }

  AccordionTable.defaults = {
    /**
     * Amount of time to animate the opening of an accordion pane.
     * @option
     * @example 250
     */
    slideSpeed: 250,
    /**
     * Allow the accordion to have multiple open panes.
     * @option
     * @example false
     */
    multiExpand: false,
    /**
     * Allow the accordion to close all panes.
     * @option
     * @example false
     */
    allowAllClosed: false
  };

  /**
   * Initializes the accordion by animating the preset active pane(s).
   * @private
   */
  AccordionTable.prototype._init = function() {
    // this.$element.attr('role', 'tablist');
    // this.$tabs = this.$element.children('li');
    this.$navs = this.$element.children('.navigation-row');

    // if (this.$tabs.length == 0) {
    //   this.$tabs = this.$element.children('[data-accordion-item]');
    // }
    this.$navs.each(function(idx, el){

      var $el = $(el);
      var id = $el.data('header-for');
      var $content = $el.next('#'+id);
          // $content = $el.find('[data-tab-content]'),
          // id = $content[0].id || Foundation.GetYoDigits(6, 'accordion'),
      var linkId = el.id || id + '-label';

      $el.attr({
        'aria-controls': id,
        'role': 'tab',
        'id': linkId,
        'aria-expanded': false,
        'aria-selected': false
      });
      $content.attr({'role': 'tabpanel', 'aria-labelledby': linkId, 'aria-hidden': true, 'id': id});
    });
    var $initActive = this.$element.find('.is-active').children('[data-tab-content]');
    if($initActive.length){
      this.down($initActive, true);
    }
    this._events();
  };

  /**
   * Adds event handlers for items within the accordion.
   * @private
   */
  AccordionTable.prototype._events = function() {
    var _this = this;

    this.$navs.each(function(){
      var $elem = $(this);
      var id = $elem.data('header-for');
      var $content = $elem.next('#'+id);
      if ($content.length) {
        $elem.off('click.zf.accordionTable keydown.zf.accordionTable')
          .on('click.zf.accordionTable', function(e){
            // ignore hyperlinks in nav rows
            if(event.target.tagName.toLowerCase() === 'a')
              return;
        // $(this).children('a').on('click.zf.accordion', function(e) {
            e.preventDefault();
            if ($elem.hasClass('is-active')) {
              console.log("click up");
              // if(_this.options.allowAllClosed || $elem.siblings().hasClass('is-active')){
                _this.up($content);
              // }
            }
            else {
              console.log("click down");
              _this.down($content);
            }
          }).on('keydown.zf.accordionTable', function(e){
            console.log("on.keydown.accordionTable");
            Foundation.Keyboard.handleKey(e, 'AccordionTable', {
              toggle: function() {
                _this.toggle($content);
              },
              next: function() {
                $elem.next().focus().trigger('click.zf.accordion');
              },
              previous: function() {
                $elem.prev().focus().trigger('click.zf.accordion');
              },
              handled: function() {
                e.preventDefault();
                e.stopPropagation();
              }
            });
          });
      }
    });
  };
  /**
   * Toggles the selected content pane's open/close state.
   * @param {jQuery} $target - jQuery object of the pane to toggle.
   * @function
   */
  AccordionTable.prototype.toggle = function($target){
    if($target.parent().hasClass('is-active')){
      if(this.options.allowAllClosed || $target.parent().siblings().hasClass('is-active')){
        this.up($target);
      }else{ return; }
    }else{
      console.log("toggle down");
      this.down($target);
    }
  };
  /**
   * Opens the accordion tab defined by `$target`.
   * @param {jQuery} $target - Accordion pane to open.
   * @param {Boolean} firstTime - flag to determine if reflow should happen.
   * @fires Accordion#down
   * @function
   */
  AccordionTable.prototype.down = function($target, firstTime) {
    console.log("down");
    var _this = this;
    if(!this.options.multiExpand && !firstTime){
      var $currentActive = this.$element.find('.is-active').next('.content-row');
      if($currentActive.length){
        this.up($currentActive);
      }
    }

    $target
      .attr('aria-hidden', false)
      .attr('style', 'display: table-row;')
      .parent('[data-tab-content]')
      .addBack()
      .prev('.navigation-row').addClass('is-active');

      // $target.slideDown(_this.options.slideSpeed);


    // if(!firstTime){
    //   Foundation._reflow(this.$element.attr('data-accordion'));
    // }
    var $navEl = $('#' + $target.attr('aria-labelledby'));
    $navEl.attr({
      'aria-expanded': true,
      'aria-selected': true
    });

    $('div:first-child div', $navEl).removeClass("arrow-right").addClass("arrow-down");

    /**
     * Fires when the tab is done opening.
     * @event Accordion#down
     */
    this.$element.trigger('down.zf.accordion', [$target]);
  };

  /**
   * Closes the tab defined by `$target`.
   * @param {jQuery} $target - Accordion tab to close.
   * @fires Accordion#up
   * @function
   */
  AccordionTable.prototype.up = function($target) {
    console.log("up");
    var $aunts = $target.prev('.navigation-row').siblings('.navigation-row'),
        _this = this;
    // var canClose = this.options.multiExpand ? $aunts.hasClass('is-active') : $target.parent().hasClass('is-active');

    // if(!this.options.allowAllClosed && !canClose){
    //   return;
    // }

    $target
      .attr('style', 'display: none;');

    // $target.slideUp(_this.options.slideSpeed);

    $target.attr('aria-hidden', true)
           .prev('.navigation-row').removeClass('is-active');

    var $navEl = $('#' + $target.attr('aria-labelledby'));
    $navEl.attr({
     'aria-expanded': false,
     'aria-selected': false
   });

    $('div:first-child div', $navEl).removeClass("arrow-down").addClass("arrow-right");


    /**
     * Fires when the tab is done collapsing up.
     * @event Accordion#up
     */
    this.$element.trigger('up.zf.accordion', [$target]);
  };

  /**
   * Destroys an instance of an accordion.
   * @fires Accordion#destroyed
   * @function
   */
  AccordionTable.prototype.destroy = function() {
    this.$element.find('[data-tab-content]').slideUp(0).css('display', '');
    this.$element.find('a').off('.zf.accordion');

    Foundation.unregisterPlugin(this);
  };

  Foundation.plugin(AccordionTable, 'AccordionTable');
}(jQuery, window.Foundation);
