var apexEndpoint = 'HOC__Occurrence__c';

var soapUrl = 'https://test.salesforce.com/services/Soap/u/40.0';
var user = 'ENTER USER HERE';
var pw = 'ENTER PASSWORD HERE' + 'ENTER SECURITY TOKEN HERE';  // second part of pw comes from My Settings -> Personal -> Reset My Security Token

var fieldDelim = '>>|';
var rowDelim = '<<|';
var keyFieldDelim = '_';

var idFld = 'ID';
var stFld = 'Start Time';
var endFld = 'End Time';
var emailFld = 'VL Email';
var statusFld = 'Claim Status';

var soapXml = 
  '<?xml version="1.0" encoding="utf-8" ?>' +
  '<soapenv:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
  '  <soapenv:Header/>' +
  '  <soapenv:Body>' +
  '    <login xmlns="urn:partner.soap.sforce.com">' +
  '      <username>XXXUSERNAMEXXX</username>' +
  '      <password>XXXPASSWORDXXX</password>' +
  '    </login>' +
  '  </soapenv:Body>' +
  '</soapenv:Envelope>';

// For BostonCares staff, approve project claims for selected row(s)
function approveClaims() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var headerFields = getHeaderFields(sheet);
  var range = sheet.getActiveRange();
  if (range.getNumRows() < 1) {
    return;
  }
  
  var rowRange = sheet.getRange(range.getRow(), 1, range.getNumRows(), sheet.getLastColumn());
  var rowValues = rowRange.getValues();
  
  processClaims(sheet, rowRange, headerFields, rowValues, range.getRow(), range.getNumRows());
}

function processClaims(sheet, rowRange, headerFields, sheetValues, startRow, numRows) {
  var loginResponse = login(user, pw);
  var urlParts = loginResponse['serverUrl'].split('Soap/');
  var url = urlParts[0] + 'apexrest/' + apexEndpoint;
  
  var idIdx = headerFields.indexOf(idFld);
  var stIdx = headerFields.indexOf(stFld);
  var endIdx = headerFields.indexOf(endFld);
  var emailIdx = headerFields.indexOf(emailFld);
  var statusIdx = headerFields.indexOf(statusFld);
  
  var idMap = { 'defaultResult': 'ERROR' };  // default to error
    
  // Salesforce's apex json parser is braindead, and xml is overkill,
  // so send the data as delimited text
  //var data = headerFields.join(fieldDelim);
  var count = 0;
  var rightNow = new Date();
  var data = headerFields[idIdx] + fieldDelim + headerFields[stIdx] + fieldDelim + headerFields[endIdx] + fieldDelim + headerFields[emailIdx];
  for (var row = 0; row < sheetValues.length; row++) {
    data += rowDelim + sheetValues[row][idIdx];
    var startDate = new Date(sheetValues[row][stIdx]);
    if (startDate < rightNow || new Date(sheetValues[row][endIdx]) < startDate) {
      continue;
    }
    data += fieldDelim + dateToYYYYMMDDHHMISS(sheetValues[row][stIdx], '-', ' ', ':');
    data += fieldDelim + dateToYYYYMMDDHHMISS(sheetValues[row][endIdx], '-', ' ', ':');
    data += fieldDelim + sheetValues[row][emailIdx];
    idMap[sheetValues[row][idIdx] + keyFieldDelim + dateToYYYYMMDD(sheetValues[row][stIdx], '-')] = row;
    count++;
  }
  //SpreadsheetApp.getUi().alert(data);
  //Logger.log(data);
  
  if (count == 0) {
    return;
  }
  var postResult = UrlFetchApp.fetch(url, {
    "method" : "post",
    "contentType" : "text/plain",
    "muteHttpExceptions": true,
    "payload": data,
    "headers": {
      "Authorization" : "Bearer " + loginResponse['sessionId']
    }
  });
  
  var rows = postResult.getContentText().split(rowDelim);
  for (var rr = 0; rr < rows.length; rr++) {
    var fields = rows[rr].split(fieldDelim);
    if (postResult.getResponseCode() == 200) {
      if (fields[0] == 'defaultResult') {
        sheet.getRange(startRow + rr, statusIdx + 1).setValue(fields[1]);
      } else {
        sheet.getRange(startRow + idMap[fields[0]], statusIdx + 1).setValue(fields[1]);
      }
    } else {
      sheet.getRange(startRow + rr, statusIdx + 1).setValue('ERROR');
    }
  }
}

function login(user, pw) {
  var resultXML = UrlFetchApp.fetch(soapUrl, {
    //"muteHttpExceptions": true,
    "method" : "post",
    "contentType" : "text/xml",
    "payload": soapXml.replace('XXXUSERNAMEXXX', esc(user)).replace('XXXPASSWORDXXX', esc(pw)),
    "headers": {
      "SOAPAction" : "login"
    }
  }).getContentText();
  
  var doc = XmlService.parse(resultXML);
  var root = doc.getRootElement();
  var ns = root.getNamespace();
  var bodyNode = root.getChild('Body', ns);
  var loginNode = bodyNode.getChildren()[0];
  var resultNode = loginNode.getChildren()[0];
  var children = resultNode.getChildren();
  var serverUrl, sessionId;
  for (var c = 0; c < children.length; c++) {
    // This is dumb but resultNode.getChild() was returning null
    if (children[c].getName() == 'serverUrl') {
      serverUrl = children[c].getText();
    }
    if (children[c].getName() == 'sessionId') {
      sessionId = children[c].getText();
    }
  }
  // URL response looks like: https://cs61.salesforce.com/services/Soap/u/40.0/00D4C0000000mYY
  return { 'serverUrl': serverUrl, 'sessionId': sessionId };
}

function esc(str) {
  return str && String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}