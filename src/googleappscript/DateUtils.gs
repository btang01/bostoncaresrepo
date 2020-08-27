var daysOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

var dateSplitRegex = /\s*[\-\/]\s*/;
var commaRegex = /\s*,\s*/;

// Returns all date strings between start/end dates that match the recurrence criteria
function getDateStrings(recurrence, type, days, startDate, endDate) {
  var id = 1;
  var dates = [];
  var daysArray = days.split(commaRegex);
  
  if (recurrence.substr(0, 9) == 'non-recur') {
    for (var d = 0; d < daysArray.length; d++) {
      dates.push({ 'id': dateToYYYYMMDD(constructDate(daysArray[d]), ''), 'value': convertDate(daysArray[d]) });
    }
  } else {
    var current = constructDate(startDate);
    if (!current) {
      current = new Date();
    }
    var end = constructDate(endDate);
    if (!end) {
      end = new Date(new Date().setFullYear(new Date().getFullYear() + 1));
    }
    
    if (recurrence.substr(0, 2) == 'da') {
      while (current <= end) {
        dates.push({ 'id': dateToYYYYMMDD(current, ''), 'value': current.toDateString() });
        current.setDate(current.getDate() + 1);
      }
    } else if (recurrence.substr(0, 4) == 'week') {
      daysArray = daysArray.map(function(d) { return d.substr(0, 3); });
      while (current <= end) {
        if (daysArray.filter(function(elem, idx, array) { return daysOfWeek[current.getDay()].substr(0, 3) == elem; }).length > 0) {
          dates.push({ 'id': dateToYYYYMMDD(current, ''), 'value': current.toDateString() });
        }
        current.setDate(current.getDate() + 1);
      }
    } else if (recurrence.substr(0, 5) == 'month') {
      if (type.substr(0, 2) == 'da') {
        while (current <= end) {
          for (var i = 0; i < daysArray.length; i++) {
            if (current.getDate() == Number(daysArray[i])) {
              dates.push({ 'id': dateToYYYYMMDD(current, ''), 'value': current.toString() });
              break;
            }
          }
          current.setDate(current.getDate() + 1);
        }
      } else {
        var typeArray = type.split(commaRegex);
        var searchDay = days.split(commaRegex)[0];
        var searchDayIdx = -1;
        for (var i = 0; i < daysOfWeek.length; i++) {
          if (daysOfWeek[i].substr(0, 3) == searchDay.substr(0, 3)) {
            searchDayIdx = i;
            break;
          }
        }
        
        var lastMonth = -1, dayCtr = 0;
        var minDate = constructDate(current.toDateString());
        var lastMatchingDate = null;
        var daysInMonth = new Date(minDate.getYear(), minDate.getMonth() + 1, 0);
        current.setDate(1);  // need to start counting at the beginning of the month
        while (current <= end) {
          var currMonth = current.getMonth();
          if (currMonth != lastMonth && lastMonth >= 0) {
            for (var i = 0; i < typeArray.length; i++) {
              if (typeArray[i].substr(0, 4) == 'last' && lastMatchingDate >= minDate) {
                dates.push({ 'id': dateToYYYYMMDD(lastMatchingDate, ''), 'value': lastMatchingDate.toDateString() });
                break;
              }
            }
            dayCtr = 0;
            daysInMonth = new Date(current.getYear(), currMonth + 1, 0);
          }
          if (searchDayIdx == current.getDay()) {
            lastMatchingDate = new Date(current.getYear(), current.getMonth(), current.getDate());
            dayCtr++;
            var match = false;
            for (var i = 0; i < typeArray.length; i++) {
              if (typeArray[i].substr(0, 4) != 'last' && dayCtr == Number(typeArray[i]) && current >= minDate) {
                dates.push({ 'id': dateToYYYYMMDD(current, ''), 'value': current.toDateString() });
                break;
              }
            }
          }
          lastMonth = currMonth;
          current.setDate(current.getDate() + 1);
        }
        // Now catch last day of the most recent month
        for (var i = 0; i < typeArray.length; i++) {
          if (typeArray[i].substr(0, 4) == 'last' && lastMatchingDate >= minDate && lastMatchingDate <= end && isLastOfMonth(lastMatchingDate)) {
            dates.push({ 'id': dateToYYYYMMDD(lastMatchingDate, ''), 'value': lastMatchingDate.toDateString() });
            break;
          }
        }
      }
    }
  }
  return dates;
}

// Turns the date descriptive fields into a single human-readable description of the date(s) of the event
function whenEventDescription(recurrence, type, days, startDate, endDate) {
  var daysArray = days.split(commaRegex);
  var retval = '';
  
  if (recurrence.substr(0, 9) == 'non-recur') {
    retval = 'Available on the following dates: ';
    for (var d = 0; d < daysArray.length; d++) {
      if (d > 0) {
        retval += ', ';
      }
      retval += dateToMMDDYYYY(constructDate(daysArray[d]));
    }
    retval += '.';
  } else {
    if (recurrence.substr(0, 2) == 'da') {
      retval = 'Available daily (including weekends)';
      retval = addStartEnd(retval, startDate, endDate);
    } else if (recurrence.substr(0, 4) == 'week') {
      retval = 'Available weekly on ' + daysArray.join(', ');
      retval = addStartEnd(retval, startDate, endDate);
    } else if (recurrence.substr(0, 5) == 'month') {
      var dd = [];
      for (var i = 0; i < daysArray.length; i++) {
        dd.push(makeAdjective(daysArray[i]));
      }
      retval = 'Available on ' + dd.join(', ') + ' of each month';
      retval = addStartEnd(retval, startDate, endDate);
    }
  }
  return retval;
}

// Turns "1" into "1st", etc
function makeAdjective(d) {
  if (d.substr(-1, 1) == '1') {
    return d + 'st';
  } else if (d.substr(-1, 1) == '2') {
    return d + 'nd';
  } else if (d.substr(-1, 1) == '3') {
    return d + 'rd';
  } else if (d && !isNaN(parseFloat(d))) {
    return d + 'th';
  } else {
    return d;
  }
}

function addStartEnd(s, startDate, endDate) {
  if (startDate && !endDate) {
    return s + ', from ' + dateToMMDDYYYY(startDate) + ' onward.';
  } else if (endDate && !startDate) {
    return s + ', from now through ' + dateToMMDDYYYY(endDate) + '.';
  } else if (startDate && endDate) {
    return s + ', from ' + dateToMMDDYYYY(startDate) + ' through ' + dateToMMDDYYYY(endDate) + '.';
  }
  return s + '.';
}

function ttl(s) {
  return String(s).trim().toLowerCase();
}

// Returns true if a date represents the last day (mon/tues/etc) of its month
// Add 7 days to the date, and see if it now falls in a new month
function isLastOfMonth(d) {
  var temp = new Date(d.getYear(), d.getMonth(), d.getDate());
  temp.setDate(temp.getDate() + 7);
  return temp.getMonth() != d.getMonth();
}

// Constructs a Date object from common formats
function constructDate(d) {
  if (!d) {
    return null;
  }
  var parts = d.toString().split(dateSplitRegex);
  if (parts.length == 3) {
    if (Number(parts[2]) > 2000) {  // MM-DD-YYYY format
      return new Date(Number(parts[2]), Number(parts[0]) - 1, Number(parts[1]));
    }
    // default: YYYY-MM-DD format
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  }
  return new Date(d);
}

// Converts YYYY-MM-DD format string to a user friendly string
function convertDate(d) {
  var dd = constructDate(d);
  return dd ? dd.toDateString() : '';
}

// Converts a date object to YYYYMMDD string
function dateToYYYYMMDD(d, sep) {
  if (!d) {
    return '';
  }
  if (!(d instanceof Date)) {
    d = new Date(d);
  }
  return d.getYear() + sep + lpad(d.getMonth() + 1) + sep + lpad(d.getDate());
}

// Converts a date object to YYYYMMDD string
function dateToYYYYMMDDHHMISS(d, sep, dsep, tsep) {
  if (!d) {
    return '';
  }
  if (!(d instanceof Date)) {
    d = new Date(d);
  }
  return d.getYear() + sep + lpad(d.getMonth() + 1) + sep + lpad(d.getDate()) + dsep + lpad(d.getHours()) +tsep + lpad(d.getMinutes()) + tsep + lpad(d.getSeconds());
}

// Converts a date object to MM-DD-YYYY string
function dateToMMDDYYYY(d) {
  if (!d) {
    return '';
  }
  return lpad(d.getMonth() + 1) + '-' + lpad(d.getDate()) + '-' + d.getYear();
}

// Pulls out the time portion
function getTimePortion(t) {
  if (t) {
    var d = new Date(t);
    return lpad(d.getHours()) + ':' + lpad(d.getMinutes());
  }
  return '';
}

function lpad(n) {
  return (n <= 9 ? '0' + n : '' + n);
}