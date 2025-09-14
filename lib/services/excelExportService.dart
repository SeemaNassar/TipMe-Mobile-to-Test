import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tipme_app/viewModels/transactionItem.dart';

class ExcelExportService {
  static Future<String> exportTransactionsToExcel(
    List<TransactionItem> transactions,
    String currency,
  ) async {
    try {
      // Create Excel workbook
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Transactions'];

      // Add headers
      sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue('Date & Time');
      sheetObject.cell(CellIndex.indexByString("B1")).value = TextCellValue('Status');
      sheetObject.cell(CellIndex.indexByString("C1")).value = TextCellValue('Amount');
      sheetObject.cell(CellIndex.indexByString("D1")).value = TextCellValue('Currency');
      sheetObject.cell(CellIndex.indexByString("E1")).value = TextCellValue('Balance');
      sheetObject.cell(CellIndex.indexByString("F1")).value = TextCellValue('Type');

      // Style headers
      for (int col = 0; col < 6; col++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add transaction data
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final rowIndex = i + 1;

        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
            TextCellValue(transaction.time);
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
            TextCellValue(_getStatusText(transaction.status));
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = 
            TextCellValue(transaction.amount);
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = 
            TextCellValue(currency);
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = 
            TextCellValue(transaction.balance);
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = 
            TextCellValue(transaction.type);
      }

      // Auto-fit columns
      for (int col = 0; col < 6; col++) {
        sheetObject.setColumnAutoFit(col);
      }

      // Generate file name
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.xlsx';

        // Mobile/Desktop platform - use file system
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(excel.encode()!);

        // File saved successfully to Documents directory
        print('Excel file saved to: $filePath');
        
        // Return the file path for UI feedback
        return filePath;
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  static String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Paid';
      case 2:
        return 'Redeemed';
      case -1:
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}
