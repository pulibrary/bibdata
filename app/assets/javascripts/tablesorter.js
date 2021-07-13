jQuery(function() {
  // tablesorter
  $("table.sortonly").tablesorter({
      widthFixed: true,
      widgets: ['stickyHeaders', 'filter', 'zebra'],
      widgetOptions: {
        stickyHeaders_offset: 50,
      }
  });
});
