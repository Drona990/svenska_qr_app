import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart' hide Border;

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  QuerySnapshot? _searchResult;
  bool _isLoading = false;

  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text("Scan to Search"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String code = barcodes.first.rawValue ?? "";
                    if (code.isNotEmpty) {
                      Navigator.pop(context);
                      _searchController.text = code;
                      _searchData(code); // Trigger your existing logic
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchData(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResult = null;
    });

    try {
      final String searchTerm = query.trim();
      var result = await FirebaseFirestore.instance
          .collection('dispatches')
          .where(
        Filter.or(
          Filter('billNo', isEqualTo: searchTerm),
          Filter('customerPin', isEqualTo: searchTerm),
        ),
      )
          .get();

      if (result.docs.isEmpty) {
        var fallbackQuery = await FirebaseFirestore.instance
            .collection('dispatches')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        final List<DocumentSnapshot> filteredDocs = fallbackQuery.docs.where((doc) {
          final List items = doc.get('items') ?? [];
          return items.any((item) => item['barcode'] == searchTerm);
        }).toList();

        if (filteredDocs.isNotEmpty) {
          setState(() {
            _searchResult = fallbackQuery;
            _isLoading = false;
          });
          _showSnackBar("Barcode found in recent records", Colors.blue);
          return;
        }
      }

      setState(() {
        _searchResult = result;
        _isLoading = false;
      });

      if (result.docs.isEmpty) {
        _showSnackBar("No record found for: $searchTerm", Colors.orange);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResult = null;
      });
      _showSnackBar("Search Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _exportToExcel() async {
    if (_searchResult == null || _searchResult!.docs.isEmpty) {
      _showSnackBar("Search for a bill first", Colors.orange);
      return;
    }

    try {
      var excel = Excel.createExcel();
      final data = _searchResult!.docs.first.data() as Map<String, dynamic>;
      final String billNo = data['billNo'] ?? "Dispatch";

      // Prepare Sheet
      excel.rename('Sheet1', billNo);
      Sheet sheet = excel[billNo];

      // Styling
      var headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      List<CellValue> headers = ["S.No", "BARCODE", "TYPE", "GWT", "LOOSE QTY", "NO OF B", "QTY"]
          .map((e) => TextCellValue(e)).toList();
      sheet.appendRow(headers);

      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      final List items = data['items'] ?? [];
      for (var item in items) {
        sheet.appendRow([
          TextCellValue(item['sno']?.toString() ?? ''),
          TextCellValue(item['barcode']?.toString() ?? ''),
          TextCellValue(item['type']?.toString() ?? ''),
          TextCellValue(item['gwt']?.toString() ?? 'STD'),
          TextCellValue(item['loose']?.toString() ?? '0'),
          TextCellValue(item['noOfB']?.toString() ?? '0'),
          TextCellValue(item['qty']?.toString() ?? '0'),
        ]);
      }

      String path;
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        path = "${dir!.path}/${billNo}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = "${dir.path}/${billNo}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(path);

        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes, flush: true);

        _showSnackBar("File Saved: ${file.path}", Colors.green);

        await Share.shareXFiles(
            [XFile(path)],
            text: 'Dispatch Manifest: $billNo'
        );
      }
    } catch (e) {
      print("Export/Save Error: $e");
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Dispatch History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.print_rounded, color: Colors.blue)),
          IconButton(onPressed: _exportToExcel, icon: const Icon(Icons.description_rounded, color: Colors.green)),
        ],
      ),
      body: BarcodeKeyboardListener(
        onBarcodeScanned: _searchData,
        child: Column(
          children: [
            _buildSearchHeader(),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(child: _buildHistoryContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Scan Bill No, Pin, or Barcode...",
          prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                onPressed: _openCameraScanner,
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchData(_searchController.text),
              ),
            ],
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onSubmitted: _searchData,
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_searchResult == null || _searchResult!.docs.isEmpty) return _emptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResult!.docs.length,
      itemBuilder: (context, index) {
        final data = _searchResult!.docs[index].data() as Map<String, dynamic>;
        final List items = data['items'] ?? [];
        return Column(
          children: [
            _buildInfoSummary(data),
            const SizedBox(height: 15),
            _buildDataTable(items),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildInfoSummary(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoTile("BILL NO", data['billNo'] ?? '-'),
          _infoTile("STATUS", data['status'] ?? 'Verified'),
        ],
      ),
    );
  }

  Widget _infoTile(String l, String v) => Column(
    children: [
      Text(l, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildDataTable(List items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Added TableBorder for professional look
          border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('S.no')),
            DataColumn(label: Text('BARCODE')),
            DataColumn(label: Text('GWT')),
            DataColumn(label: Text('LOOSE')),
            DataColumn(label: Text('NO OF B')),
            DataColumn(label: Text('QTY')),
          ],
          rows: items.asMap().entries.map((entry) {
            final item = entry.value;
            return DataRow(cells: [
              DataCell(Text((entry.key + 1).toString())),
              DataCell(Text(item['barcode'] ?? '')),
              DataCell(Text(item['gwt'] ?? '0')),
              DataCell(Text(item['loose'] ?? '0')),
              DataCell(Text(item['noOfB'] ?? '0')),
              DataCell(Text(item['qty'] ?? '0')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.manage_search, size: 80, color: Colors.grey),
        Text("Ready for Scan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
