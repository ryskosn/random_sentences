/**
 * Sheet から object にする
 * @param {Object} sheet
 * @param {Object}
 */
function convertFromSheet(sheet) {
    var rows = sheet.getDataRange().getValues();
    var keys = rows.splice(0, 1)[0];

    // filetering
    rows = rows.filter(function (row) {
        // enabled == true
        return row[2] === true;
    });

    var result = {};
    result["sheetName"] = sheet.getName();
    result["rows"] = rows.map(function (row) {
        var obj = {};
        row.map(function (item, index) {
            obj[String(keys[index])] = String(item);
        });
        return obj;
    });
    return result;
}

/**
 * 各シートのデータを filter した上で object にする
 * @returns {Object}
 */
function getObjectFromSheets() {
    const sheets = SpreadsheetApp.getActive().getSheets();
    return { sheets: sheets.map(convertFromSheet) };
}


/**
 * web app として公開する
 */
function doGet() {
    const data = getObjectFromSheets();
    return ContentService.createTextOutput(JSON.stringify(data, null, 2))
        .setMimeType(ContentService.MimeType.JSON);
}