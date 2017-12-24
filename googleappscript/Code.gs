var ClaimsSheetName = 'Claims';

// Create a menu for volunteer leaders
function onOpen() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  //ss.addMenu('Volunteer Leaders', [
  //  { name: 'Filter Projects', functionName: 'filterProjects' },
  //  { name: 'Claim Selected Project', functionName: 'claimProject' }
  //]);
  ss.addMenu('Boston Cares', [
    { name: 'Approve', functionName: 'approveClaims' }
  ]);
}

// Claim one or more opportunities for the selected project
function claimProject() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var headerFields = getHeaderFields(sheet);
  var selectedRowRange = getSelectedRowRange(sheet);
  if (selectedRowRange === null) {
    return;
  }
  
  var template = populateTemplateDates(HtmlService.createTemplateFromFile('ClaimForm.html'), headerFields, selectedRowRange);
  var html = template.evaluate().setHeight(600);
  SpreadsheetApp.getUi().showModalDialog(html, 'Claim Project Dates');
}

// Pushes opportunity dates into the pending tab after the user claims them
function claimDates(id, startTime, endTime, email, dates) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(ClaimsSheetName);
  var headerFields = getHeaderFields(sheet);
  var selectedRowValues = getSelectedRowRange(sheet);
  if (selectedRowValues === null) {
    return;
  }
  
  // Need to fix up time fields because of google's asinine autoconversion
  var idIdx = headerFields.indexOf('ID');
  var stIdx = headerFields.indexOf('Start Time');
  var etIdx = headerFields.indexOf('End Time');
  
  // Add to pending/claims tab
  var pendingTab = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(ClaimsSheetName);
  var timeOfEvent = getTimePortion(selectedRowValues[stIdx]) + '-' + getTimePortion(selectedRowValues[etIdx]);
  for (var d = 0; d < dates.length; d++) {
    var values = [id, 'Occurrence', 'Unapproved', dateToYYYYMMDD(dates[d], '-') + ' ' + startTime, dateToYYYYMMDD(dates[d], '-') + ' ' + endTime, dateToYYYYMMDD(new Date(), '-'), '', email.trim()];
    pendingTab.appendRow(values);
  }
  
  return 'Completed.';
}

// Pushes date list onto a template
function populateTemplateDates(template, headerFields, selectedRow) {
  var recurrence = ttl(selectedRow[headerFields.indexOf('Event Recurrence')]);
  var type = ttl(selectedRow[headerFields.indexOf('Recurrence Type')]);
  var days = ttl(selectedRow[headerFields.indexOf('Days')]);
  var startDate = selectedRow[headerFields.indexOf('Start Date')].trim();
  var endDate = selectedRow[headerFields.indexOf('End Date')].trim();
  var startTime = selectedRow[headerFields.indexOf('Start Time')].trim();
  var endTime = selectedRow[headerFields.indexOf('End Time')].trim();
  
  template.dates = getDateStrings(recurrence, type, days, startDate, endDate);
  for (var i = 0; i < template.dates.length; i++) {
    template.dates[i]['value'] += ' (' + getTimePortion(startTime) + ' - ' + getTimePortion(endTime) + ')';
  }
  return template;
}

// Returns a range for the row that the user currently has selected
function getSelectedRowRange(sheet) {
  var range = sheet.getActiveRange();
  var numRows = range.getNumRows();
  if (numRows < 1) {
    Browser.msgBox('You must select a row in the spreadsheet to claim it!');
    return null;
  } else if (numRows > 1) {
    Browser.msgBox('You cannot claim more than one project at a time. Select just a single row.');
    return null;
  }
  var rowRange = sheet.getRange(range.getRow(), 1, 1, sheet.getLastColumn());
  return rowRange.getValues()[0].map(String);
}

// Gets an array of the header field names
function getHeaderFields(sheet) {
  var headerRow = sheet.getRange(1, 1, 1, sheet.getLastColumn());
  return headerRow.getValues()[0].map(String);
}

// Gets a map of field names to positions
function getHeaderMap(sheet) {
  var headerFields = getHeaderFields(sheet);
  var headerMap = {};
  for (var i = 0; i < headerFields.length; i++) {
    headerMap[headerFields[i]] = i;
  }
  return headerMap;
}


////////// OBSOLETE STUFF FOLLOWS //////////


// Hide all rows, then unhide those that match the user-supplied pattern
function filterProjects() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getActiveSheet();
  var input = Browser.inputBox("Show only projects matching this text:");
  if (input == 'cancel') {
    return;
  }
  
  var regexp = new RegExp(input, 'i');
  var cols = sheet.getLastColumn();
  var rows = sheet.getLastRow();
  
  sheet.hideRows(2, rows - 1);
  
  for (var row = 2; row <= rows ; row++) {
    for (var col = 1; col <= cols; col++) {
      var cell = sheet.getRange(row, col, 1, 1);
      var val = cell.getValue();
      if (regexp.test(val)) {
        sheet.showRows(row, 1);
        continue;
      }
    }
  }
}

// Finds the sheet in the current drive folder starting with 'Claims'
function getClaimsSheet() {
  var sheetIds = [];
  var ssFile = DriveApp.getFileById(SpreadsheetApp.getActiveSpreadsheet().getId());
  var parents = ssFile.getParents();
  while (parents.hasNext()) {
    var parent = parents.next();
    var files = parent.getFiles();
    while (files.hasNext()) {
      var file = files.next();
      var name = file.getName();
      if (name.toLowerCase().startsWith('claims')) {
        sheetIds.push(file.getId());
      }
    }
  }
  if (sheetIds.length == 1) {
    return sheetIds[0];
  }
  return null;
}
//var pendingSheetId = getClaimsSheet();
//if (pendingSheetId === null) {
//  return 'Error: could not find claims sheet!';
//}
//var pendingTab = SpreadsheetApp.openById(pendingSheetId).getSheetByName(ClaimsSheetName);