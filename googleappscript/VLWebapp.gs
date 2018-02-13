// Set this to the ID of the spreadsheet (which we won't know when running as a deployed webapp)
var spreadsheetID = '18T4H54aO0TTnwePaYZUf1gVubnRgI4m0OF6i5J7JydU';
var MasterSheetName = 'Master List';

// FIXME TODO: STUFF TO DO IN SPREADSHEET:
// - delete contents past last column

function doGet(e) {
  return handleRequest();
}

function handleRequest() {
  return HtmlService.createHtmlOutputFromFile('VLWebappPage.html');
}

function test() {
  SpreadsheetApp.getUi().showModalDialog(HtmlService.createHtmlOutputFromFile('VLWebappPage.html'), 'Claim Project Dates');
}

// Returns an array of spreadsheet data for display on the deployed web page
function getStartingData() {
  var ss = getActiveSpreadsheet();
  var sheet = ss.getSheetByName(MasterSheetName);
  var values = sheet.getDataRange().getValues();
  var fieldPos = getHeaderMap(sheet);
  
  var eventRecurrence = fieldPos['Event Recurrence'];
  var recurrenceType = fieldPos['Recurrence Type'];
  var daysIdx = fieldPos['Days'];
  var startDate = fieldPos['Start Date'];
  var endDate = fieldPos['End Date'];
  var startTime = fieldPos['Start Time'];
  var endTime = fieldPos['End Time'];
  var dateListIdx = fieldPos['Date List'];
  var whenIdx = fieldPos['When is Event'];
  var activeIdx = fieldPos['Is Active'];
  
  var fieldIndexesToDelay = [
    fieldPos['Description of Event'],
    fieldPos['Public Transportation and Parking'],
    //fieldPos['Contact Name'],
    //fieldPos['Contact e-mail'],
    //fieldPos['Contact phone'],
    //fieldPos['Onsite Contact (if different)'],
    fieldPos['What To Know About This Project']
  ];
  var fieldIndexesToHide = [
    eventRecurrence,
    recurrenceType,
    daysIdx,
    startDate,
    endDate,
    dateListIdx
  ];
  
  var cols = [];
  var len = values[0].length;
  for (var col = 0; col < len; col++) {
    var priority = undefined;
    var visibility = true;
    var coldef = {
      title: values[0][col],
      visible: true
    };
    if (fieldIndexesToDelay.indexOf(col) >= 0) {
      coldef['responsivePriority'] = 999999;
    }
    if (fieldIndexesToHide.indexOf(col) >= 0) {
      coldef['visible'] = false;
    }
    if (col == fieldPos['Claim this Project']) {
      coldef['data'] = null;
      coldef['defaultContent'] = '<button class="action" onclick="claimProject(this);return false;">Sign Up as Volunteer Leader for this Project</button>';
    }
    cols.push(coldef);
  }
  
  var newvals = [];
  var datelist = [];
  for (var row = 1; row < values.length; row++) {
    if (values[row]) {
      var myrow = [];
      if (values[row][activeIdx] != 1) {
        continue;
      }
      for (var col = 0; col < values[row].length; col++) {
        var val = String(values[row][col]);
        if (col == whenIdx) {
          var recurrence = ttl(values[row][eventRecurrence]);
          var type = ttl(values[row][recurrenceType]);
          var days = ttl(values[row][daysIdx]);
          var start = values[row][startDate];
          var end = values[row][endDate];
          val = whenEventDescription(recurrence, type, days, start, end);
        } else if (col == dateListIdx) {
          var ds = getDateStrings(recurrence, type, days, start, end);
          for (var i = 0; i < ds.length; i++) {
            ds[i]['value'] += ' (' + getTimePortion(values[row][startTime]) + ' - ' + getTimePortion(values[row][endTime]) + ')';
          }
          val = ds.map(function(x){ return x['value']; }).join(',');
        } else if (col == startTime || col == endTime) {
          val = getTimePortion(values[row][col]);
        }
        myrow.push(val);
      }
      newvals.push(myrow);
    }
  }
    
  return { data: newvals, columns: cols, dates: datelist, header: fieldPos };
}

// Returns the active spreadsheet
function getActiveSpreadsheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  if (ss == null) {
    ss = SpreadsheetApp.openById(spreadsheetID);
  }
  return ss;
}
