import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class WordReportGenerator {
  static String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Future<Map<String, dynamic>> generateReport({
    required List<Map<String, dynamic>> reportData,
    required double totalIncome,
    required double totalExpense,
    required double finalBalance,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get directory untuk menyimpan file
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Coba save ke folder Download publik
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback ke Documents jika Download tidak ada
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Laporan_Keuangan_$timestamp.doc';
      final filePath = '${directory!.path}/$fileName';

      // Buat konten HTML untuk Word document
      final htmlContent = _generateHtmlContent(
        reportData: reportData,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        finalBalance: finalBalance,
        startDate: startDate,
        endDate: endDate,
      );

      // Simpan file
      final file = File(filePath);
      await file.writeAsString(htmlContent);

      return {
        'success': true, 
        'path': filePath,
        'fileName': fileName, // TAMBAHKAN INI
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static String _generateHtmlContent({
    required List<Map<String, dynamic>> reportData,
    required double totalIncome,
    required double totalExpense,
    required double finalBalance,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    // Gunakan format tanpa locale untuk menghindari LocaleDataException
    final reportDate = DateFormat('dd MMMM yyyy').format(now);

    String filterInfo = '';
    if (startDate != null && endDate != null) {
      filterInfo =
          '''
        <p style="text-align: center; margin: 5px 0; color: #000; font-size: 11pt;">
          <strong>Periode Laporan:</strong> ${_formatDate(startDate)} s/d ${_formatDate(endDate)}
        </p>
      ''';
    }

    // Generate table rows
    String tableRows = '';
    for (var item in reportData) {
      final incomeStr = item['income'] > 0
          ? 'Rp ${_formatCurrency(item['income'])}'
          : '-';
      final expenseStr = item['expense'] > 0
          ? 'Rp ${_formatCurrency(item['expense'])}'
          : '-';
      final balanceStr = 'Rp ${_formatCurrency(item['balance'])}';

      tableRows +=
          '''
        <tr>
          <td style="text-align: center; padding: 10px; border: 1px solid #000;">${item['no']}</td>
          <td style="padding: 10px; border: 1px solid #000; text-align: left;">${item['description']}</td>
          <td style="text-align: center; padding: 10px; border: 1px solid #000;">${_formatDate(item['date'])}</td>
          <td style="text-align: right; padding: 10px; border: 1px solid #000;">$incomeStr</td>
          <td style="text-align: right; padding: 10px; border: 1px solid #000;">$expenseStr</td>
          <td style="text-align: right; padding: 10px; border: 1px solid #000;">$balanceStr</td>
        </tr>
      ''';
    }

    // HTML Content dengan styling formal hitam putih
    return '''
<!DOCTYPE html>
<html xmlns:v="urn:schemas-microsoft-com:vml"
xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns:m="http://schemas.microsoft.com/office/2004/12/omml"
xmlns="http://www.w3.org/TR/REC-html40">

<head>
<meta http-equiv=Content-Type content="text/html; charset=utf-8">
<meta name=ProgId content=Word.Document>
<meta name=Generator content="Microsoft Word 15">
<meta name=Originator content="Microsoft Word 15">
<title>Laporan Keuangan</title>
<style>
@page {
  size: A4;
  margin: 2.5cm;
}

body {
  font-family: 'Times New Roman', 'Georgia', serif;
  font-size: 12pt;
  line-height: 1.5;
  color: #000;
  margin: 0;
  padding: 0;
}

.header {
  text-align: center;
  margin-bottom: 30px;
  padding-bottom: 10px;
  border-bottom: 2px solid #000;
}

.header h1 {
  margin: 0 0 10px 0;
  font-size: 18pt;
  color: #000;
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 2px;
}

.header p {
  margin: 3px 0;
  font-size: 11pt;
  color: #000;
}

.summary-box {
  border: none;
  padding: 15px 0;
  margin: 25px 0;
  page-break-inside: avoid;
}

.summary-title {
  font-size: 13pt;
  font-weight: bold;
  color: #000;
  margin-bottom: 12px;
  text-align: center;
  text-transform: uppercase;
  padding-bottom: 8px;
}

.summary-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

.summary-table td {
  padding: 10px;
  border: 1px solid #000;
  font-size: 11pt;
  background-color: #fff;
  color: #000;
}

.summary-label {
  font-weight: bold;
  width: 50%;
  color: #000;
}

.summary-value {
  font-weight: bold;
  text-align: right;
  width: 50%;
  color: #000;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 25px;
  page-break-inside: auto;
}

tr {
  page-break-inside: avoid;
  page-break-after: auto;
}

thead {
  display: table-header-group;
}

thead tr {
  background-color: #fff;
  color: #000;
  font-weight: bold;
  border: 2px solid #000;
}

thead th {
  padding: 12px 8px;
  text-align: center;
  border: 1px solid #000;
  font-size: 11pt;
  font-weight: bold;
  background-color: #fff;
  color: #000;
}

tbody tr {
  background-color: #fff;
}

td {
  padding: 10px 8px;
  border: 1px solid #000;
  font-size: 10pt;
  color: #000;
  background-color: #fff;
}

tfoot tr {
  background-color: #fff;
  font-weight: bold;
}

tfoot td {
  padding: 12px 8px;
  border: 2px solid #000;
  font-size: 11pt;
  font-weight: bold;
  color: #000;
  background-color: #fff;
}

.footer {
  margin-top: 50px;
  padding-top: 15px;
  text-align: center;
  font-size: 9pt;
  color: #000;
  page-break-inside: avoid;
}

.signature-section {
  margin-top: 40px;
  margin-bottom: 30px;
  width: 100%;
  page-break-inside: avoid;
}

.signature-table {
  width: 100%;
  border: none;
  border-collapse: collapse;
}

.signature-table td {
  border: none;
  padding: 10px;
  vertical-align: top;
}

.signature-label {
  font-weight: bold;
  margin-bottom: 10px;
  font-size: 11pt;
}

.signature-line {
  margin-top: 70px;
  border-top: 1px solid #000;
  padding-top: 5px;
  font-weight: normal;
  font-size: 10pt;
}

@media print {
  body {
    margin: 0;
    padding: 0;
  }
  
  .summary-box, .signature-section, tfoot {
    page-break-inside: avoid;
  }
}
</style>
</head>

<body>

<!-- Header -->
<div class="header">
  <h1>Laporan Keuangan</h1>
  <p><strong>Tanggal Cetak:</strong> $reportDate</p>
  $filterInfo
</div>

<!-- Summary Box -->
<div class="summary-box">
  <div class="summary-title">Ringkasan Keuangan</div>
  <table class="summary-table">
    <tr>
      <td class="summary-label">Total Pemasukan</td>
      <td class="summary-value">Rp ${_formatCurrency(totalIncome)}</td>
    </tr>
    <tr>
      <td class="summary-label">Total Pengeluaran</td>
      <td class="summary-value">Rp ${_formatCurrency(totalExpense)}</td>
    </tr>
    <tr style="background-color: #fff;">
      <td class="summary-label" style="font-size: 12pt; background-color: #fff;">Saldo Akhir</td>
      <td class="summary-value" style="font-size: 12pt; background-color: #fff;">Rp ${_formatCurrency(finalBalance)}</td>
    </tr>
  </table>
</div>

<!-- Transaction Table -->
<table>
  <thead>
    <tr>
      <th style="width: 5%;">No</th>
      <th style="width: 35%; text-align: left;">Deskripsi</th>
      <th style="width: 12%;">Tanggal</th>
      <th style="width: 16%;">Pemasukan (Rp)</th>
      <th style="width: 16%;">Pengeluaran (Rp)</th>
      <th style="width: 16%;">Saldo (Rp)</th>
    </tr>
  </thead>
  <tbody>
    $tableRows
  </tbody>
  <tfoot>
    <tr>
      <td colspan="3" style="text-align: center;">
        <strong>TOTAL</strong>
      </td>
      <td style="text-align: right;">
        <strong>Rp ${_formatCurrency(totalIncome)}</strong>
      </td>
      <td style="text-align: right;">
        <strong>Rp ${_formatCurrency(totalExpense)}</strong>
      </td>
      <td style="text-align: right;">
        <strong>Rp ${_formatCurrency(finalBalance)}</strong>
      </td>
    </tr>
  </tfoot>
</table>

<!-- Signature Section -->
<div class="signature-section">
  <table class="signature-table">
    <tr>
      <td style="width: 60%; border: none;">&nbsp;</td>
      <td style="width: 40%; text-align: center; border: none;">
        <p style="margin: 0 0 70px 0; font-weight: normal; font-size: 11pt;">Mengetahui,</p>
        <p style="margin: 0; padding-top: 0; font-size: 10pt;">
          ( ____________________ )
        </p>
      </td>
    </tr>
  </table>
</div>

<!-- Footer -->
<div class="footer">
  <p style="margin: 3px 0; font-size: 9pt;">Dokumen ini dibuat secara otomatis oleh sistem</p>
  <p style="margin: 3px 0; font-size: 8pt; font-style: italic;">Dicetak: ${DateFormat('dd MMMM yyyy, HH:mm').format(now)} WIB</p>
</div>

</body>
</html>
    ''';
  }
}