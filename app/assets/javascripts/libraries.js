// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){
  // tablesorter editable position
  $("table.reorder").tablesorter({
    sortList: [[0,0]],
    widthFixed: true,
    widgets: ['stickyHeaders', 'filter', 'zebra', 'editable'],
    widgetOptions: {
      stickyHeaders_offset: 50,
      editable_columns       : [0],       // or "0-2" (v2.14.2); point to the columns to make editable (zero-based index)
      editable_enterToAccept : true,          // press enter to accept content, or click outside if false
      editable_autoAccept    : true,          // accepts any changes made to the table cell automatically (v2.17.6)
      editable_autoResort    : true,         // auto resort after the content has changed.
      editable_validate      : function(text, original, columnIndex){
        if(Math.floor(text) == text && $.isNumeric(text))
          return text;
        else
          return original; },
      editable_focused       : function(txt, columnIndex, $element) {
        // $element is the div, not the td
        // to get the td, use $element.closest('td')
        $element.addClass('focused');
      },
      editable_blur          : function(txt, columnIndex, $element) {
        // $element is the div, not the td
        // to get the td, use $element.closest('td')
        $element.removeClass('focused');
      },
      editable_selectAll     : function(txt, columnIndex, $element){
        // note $element is the div inside of the table cell, so use $element.closest('td') to get the cell
        // only select everthing within the element when the content starts with the letter "B"
        return /^b/i.test(txt) && columnIndex === 0;
      },
      editable_wrapContent   : '<div>',       // wrap all editable cell content... makes this widget work in IE, and with autocomplete
      editable_trimContent   : true,          // trim content ( removes outer tabs & carriage returns )
      editable_noEdit        : 'no-edit',     // class name of cell that is not editable
      editable_editComplete  : 'editComplete' // event fired after the table content has been edited
    }
  })
  // config event variable new in v2.17.6
  .children('tbody').on('editComplete', 'td', function(event, config){
    var $this = $(this),
      newContent = $this.text(),
      cellIndex = this.cellIndex, // there shouldn't be any colspans in the tbody
      rowIndex = $this.closest('tr').attr('id'); // data-row-index stored in row id
    $.ajax({
      method: "PATCH",
      url: "libraries/" + rowIndex,
      data: { order: newContent },
      dataType: 'script'
    });
  });
})
