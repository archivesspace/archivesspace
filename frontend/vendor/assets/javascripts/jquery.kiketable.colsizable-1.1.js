/*
 * jQuery kiketable.colsizable plugin
 * Version 1.1 (20-MAR-2009)
 * @requires jQuery v1.3.2 or later (http://jquery.com)
 * @requires jquery.event.drag-1.4.js (http://blog.threedubmedia.com/2008/08/eventspecialdrag.html)
 *
 * Examples at: http://www.ita.es/jquery/jquery.kiketable.colsizable.htm
 * Copyright (c) 2007-2009 Enrique Melendez Estrada
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 */
(function($){

  $.fn.kiketable_colsizable = function(o) {
    // default parameters, properties or settings
    o = $.extend({}, $.fn.kiketable_colsizable.defaults, o);
    o.dragProxy = (o.dragProxy === "line" ) ? false : true;

    this
      .filter("table:not(."+o.namespace+")") // only for "virgin" html table(s)
      .addClass(o.namespace)
      .each(function(index){
        o.renderTime = new Date().getTime();
        //
        // global variables
        //
        var oTable =	this,
          $Table =	$(this),
          _Cols =		oTable.getElementsByTagName("col");
        ;
        _Cols.length && $(o.dragCells,this)
          .each(function(index){
            if (!$(this).hasClass('kiketable-th'))
              $(this).addClass('kiketable-th').wrapInner('<div class="kiketable-th-text"></div>');
            $('<div class="'+o.classHandler+'" title="'+ o.title+'"></div>')
              .prependTo(this)
              .each(function(){
                //
                // global properties
                //
                this.td =	this.parentNode; // alias for TD / CELL of this, if jerarchy changes in future, only depends on this var
                this.$td =	$(this.td);
                this.col = _Cols[this.td.cellIndex];
              })
              .dblclick( function() {
                // if loading fast, only once...
                if (this.wtd == null){
                  this.wtd =		this.col.offsetWidth;
                  this.wtd0=		this.wtd;
                };

                // change column width
                var minimized = this.wtd == o.minWidth;
                this.wtd = (minimized) ? this.wtd0 : o.minWidth;
                this.col.style.width = this.wtd + "px";

                // change table width (if not fixed)
                if(!o.fixWidth){
                  var d = this.wtd0-o.minWidth;
                  oTable.style.width = $Table.width()+((minimized)?d:-d)+"px";
                };
                $(this).trigger('minimized');
              })
              //
              // bind a dragstart event, return the proxy element
              //
              .bind( 'dragstart', function(e){
                this.cell_width =	this.$td.width();
                this.table_width =	$Table.width();
                this.left0 =		e.offsetX;
                this.d1 = this.cell_width - this.left0; // precalc for drag event
                this.d2 = o.minWidth - this.d1; // precalc for drag event

                return $(this)
                  .clone()
                  .appendTo(this.td)
                  .css("opacity",o.dragOpacity)
                  .css((o.dragProxy)?{
                    top:	this.$td.offset().top,
                    left:	this.$td.offset().left,
                    width:	this.cell_width
                  }:{
                    top:	this.$td.offset().top,
                    left:	e.offsetX
                  })
                  .removeClass(o.classHandler)
                  .addClass(	(o.dragProxy)? o.classDragArea :	o.classDragLine)
                  .height($Table.height())
              })
              //
              // bind a drag event, update proxy position
              //
              .bind( 'drag', (o.dragMove || o.dragProxy)? function(e){
                var w = e.offsetX + this.d1;
                if(w - this.d2 - this.d1 >= 0){
                  e.dragProxy.style.width = w + "px"; //$(e.dragProxy).css({width: w}) ;
                  if (o.dragMove){
                    this.col.style.width = w +"px"; // cell width
                    if(!o.fixWidth){
                      oTable.style.width = (this.table_width - this.cell_width+ w) + "px";
                    };
                  };
                }
              }: function(e){
                var x = e.offsetX;
                if (x - this.d2 >= 0)
                  e.dragProxy.style.left = x+"px"; //$(e.dragProxy).css({left: e.offsetX});
              })
              //
              // bind a dragend event, remove proxy
              //
              .bind( 'dragend', function(e){
                if (!o.dragMove){
                  var delta = parseInt(e.dragProxy.style.left) - this.left0;
                  this.col.style.width = (o.dragProxy) ? e.dragProxy.style.width : (this.cell_width + delta)+"px"; // cell width
                  // change table width (if not fixed)
                  if(!o.fixWidth)
                    oTable.style.width = ((o.dragProxy) ? this.table_width - this.cell_width + parseInt(e.dragProxy.style.width) : this.table_width + delta)+"px";
                }
                $(e.dragProxy)[o.fxHide](o.fxSpeed, function(){$(this).remove()});
                $(this).trigger('minimized');
              })
              .bind('minimized', function(e){
                $(this.col)[(parseInt(this.col.style.width) <= o.minWidth) ? "addClass":"removeClass"](o.classMinimized)
              });
          });
        o.renderTime = new Date().getTime() - o.renderTime;
        o.onLoad();
      });
    return this;
  };
  $.fn.kiketable_colsizable.defaults = {
    dragCells :		"tr:first > *",// cells for allocating column sizing handlers (by default: all cells of first row)
    dragMove :		true,		// see column moving its width? (true/false)
    dragProxy :		"line",		// Shape of dragging ghost ("line"/"area")
    dragOpacity :	.3,			// Opacity for dragging ghost (0 - 1)
    minWidth :		8,			// width for minimized column (px)
    fixWidth :		false,		// table with fixed width? (true/false)
    fxHide :		"fadeOut",	// effect for hiding (fadeOut/hide/slideUp)
    fxSpeed:		200,		// speed for hiding (miliseconds)
    namespace :		"kiketable-colsizable",
    classHandler :	"kiketable-colsizable-handler",
    classDragLine :	"kiketable-colsizable-dragLine",
    classDragArea :	"kiketable-colsizable-dragArea",
    classMinimized: "kiketable-colsizable-minimized",
    title :			'Expand/Collapse this column',
    renderTime :	0,
    onLoad : function(){}
  };
}) (jQuery);
