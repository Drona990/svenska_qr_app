import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added
import 'package:image_picker/image_picker.dart'; // Added
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:intl/intl.dart';

class DesktopDispatchWorkstation extends StatefulWidget {
  const DesktopDispatchWorkstation({super.key});

  @override
  State<DesktopDispatchWorkstation> createState() => _DesktopDispatchWorkstationState();
}

class _DesktopDispatchWorkstationState extends State<DesktopDispatchWorkstation> {
  final _pinController = TextEditingController();
  final _billController = TextEditingController();
  final _qtyController = TextEditingController();
  final _boxController = TextEditingController();
  final _looseController = TextEditingController();

  final _gwtController = TextEditingController();
  final _looseQtyController = TextEditingController(); // Added for Loose Qty
  final FocusNode _gwtFocus = FocusNode();
  final FocusNode _looseQtyFocus = FocusNode(); // Added focus for Loose Qty

  final List<Map<String, dynamic>> _liveItems = [];
  bool _isStandardMode = true;
  bool _isSaving = false;
  bool _isUploading = false; // Added loading state for image upload

  File? _currentImage; // Added to store selected file
  final ImagePicker _picker = ImagePicker(); // Added picker instance

  final FocusNode _masterFocus = FocusNode();
  final TextEditingController _terminalController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final TextEditingController _historySearchController = TextEditingController();
  QuerySnapshot? _historySearchResult;
  bool _isHistoryLoading = false;
  bool _showHistoryOnly = false;

  int get _verifiedBoxCount => _liveItems.where((item) => item['type'] == 'BOX').length;
  int get _verifiedLooseCount => _liveItems.where((item) => item['type'] == 'LOOSE').length;

  bool get _isConfigComplete {
    return _pinController.text.isNotEmpty &&
        _billController.text.isNotEmpty &&
        _qtyController.text.isNotEmpty &&
        _boxController.text.isNotEmpty &&
        _looseController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    List<TextEditingController> ctrls = [
      _pinController, _billController, _qtyController,
      _boxController, _looseController, _gwtController, _looseQtyController
    ];
    for (var controller in ctrls) {
      controller.addListener(() => setState(() {}));
    }
  }

  // --- NEW: IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _currentImage = File(image.path));
    }
  }

  // --- NEW: FIREBASE STORAGE UPLOAD ---
  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => _isUploading = true);
      String fileName = 'dsktp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('dispatch_photos').child(fileName);
      TaskSnapshot snapshot = await ref.putFile(image);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showSnack("Upload Failed: $e", Colors.red);
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _searchHistory(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isHistoryLoading = true;
      _historySearchResult = null;
    });

    try {
      final String searchTerm = query.trim();
      var result = await FirebaseFirestore.instance.collection('dispatches').where(
        Filter.or(
          Filter('billNo', isEqualTo: searchTerm),
          Filter('customerPin', isEqualTo: searchTerm),
        ),
      ).get();

      setState(() {
        _historySearchResult = result;
        _isHistoryLoading = false;
      });
    } catch (e) {
      setState(() => _isHistoryLoading = false);
    }
  }

  void _onScanReceived(String code) async {
    final scannedCode = code.trim();
    if (scannedCode.isEmpty || _isSaving || _isUploading || !_isConfigComplete) return;

    // MANDATORY PHOTO CHECK
    if (_currentImage == null) {
      _playAlert(true);
      _showSnack("REQUIRED: Please select item image first!", Colors.red);
      return;
    }

    // LOOSE SCAN LOGIC: Verify GWT and Qty
    if (!_isStandardMode) {
      if (_gwtController.text.isEmpty || _looseQtyController.text.isEmpty) {
        _playAlert(true);
        _showSnack("REQUIRED: Enter GWT and Qty before scanning!", Colors.red);
        _gwtFocus.requestFocus();
        return;
      }
    }

    int target = _isStandardMode
        ? (int.tryParse(_boxController.text) ?? 0)
        : (int.tryParse(_looseController.text) ?? 0);
    int current = _isStandardMode ? _verifiedBoxCount : _verifiedLooseCount;

    if (scannedCode == _pinController.text) {
      if (current < target) {
        // Upload image first
        String? imageUrl = await _uploadImage(_currentImage!);
        if (imageUrl == null) return;

        setState(() {
          _liveItems.insert(0, {
            'sno': _liveItems.length + 1,
            'barcode': scannedCode,
            'type': _isStandardMode ? 'BOX' : 'LOOSE',
            'qty': _isStandardMode ? _qtyController.text : _looseQtyController.text,
            'gwt': _isStandardMode ? 'STD' : _gwtController.text,
            'imgUrl': imageUrl,
            'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          });

          _currentImage = null; // Clear image for next scan
          if (!_isStandardMode) {
            _gwtController.clear();
            _looseQtyController.clear();
          }
        });
        _playAlert(false);

        if (_verifiedBoxCount == (int.tryParse(_boxController.text) ?? 0) &&
            _verifiedLooseCount == (int.tryParse(_looseController.text) ?? 0)) {
          _saveToFirebase();
        }
      } else {
        _showSnack("${_isStandardMode ? 'Boxes' : 'Loose Items'} Completed!", Colors.orange);
      }
    } else {
      _playAlert(true);
      _showSnack("Invalid Scan: $scannedCode", Colors.red);
    }
    _terminalController.clear();
    _masterFocus.requestFocus();
  }

  void _deleteRow(int index) async {
    // Delete image from storage to save space
    String? url = _liveItems[index]['imgUrl'];
    if (url != null) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        debugPrint("Error deleting image: $e");
      }
    }

    setState(() {
      _liveItems.removeAt(index);
      for (int i = 0; i < _liveItems.length; i++) {
        _liveItems[i]['sno'] = _liveItems.length - i;
      }
    });
    _showSnack("Row Deleted", Colors.black);
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('dispatches').add({
        'billNo': _billController.text,
        'customerPin': _pinController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'items': _liveItems,
        'status': 'Verified',
      });
      _showSnack("Dispatch Saved Successfully!", Colors.green);
      _resetStation();
    } catch (e) {
      _showSnack("Upload Error", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetStation() {
    _pinController.clear(); _billController.clear(); _qtyController.clear();
    _boxController.clear(); _looseController.clear(); _liveItems.clear();
    _terminalController.clear(); _gwtController.clear(); _looseQtyController.clear();
    _currentImage = null;
  }

  void _playAlert(bool isError) {
    _audioPlayer.play(AssetSource(isError ? 'sound/beep-warning.mp3' : 'sound/beep.mp3'));
    if (isError) HapticFeedback.heavyImpact();
  }

  void _showSnack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _showHistoryOnly ? _buildFullHistoryView() : Row(
                      children: [
                        Expanded(flex: 3, child: _buildEntryForm()),
                        const SizedBox(width: 24),
                        Expanded(flex: 6, child: _buildTerminalView()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 70, color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.precision_manufacturing, color: Colors.blueAccent, size: 28),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.dashboard, color: !_showHistoryOnly ? Colors.blueAccent : Colors.white24),
            onPressed: () => setState(() => _showHistoryOnly = false),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.history, color: _showHistoryOnly ? Colors.blueAccent : Colors.white24),
            onPressed: () => setState(() => _showHistoryOnly = true),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(_showHistoryOnly ? "CENTRAL ARCHIVE" : "UNIFIED DISPATCH STATION",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.circle, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          const Text("SYSTEM ONLINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEntryForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text("DISPATCH ENTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          _input("Customer P/N", _pinController, Icons.pin_drop),
          _input("Bill No", _billController, Icons.receipt),
          _input("Total Qty", _qtyController, Icons.inventory),
          _input("Boxes", _boxController, Icons.all_inbox),
          _input("Loose", _looseController, Icons.unarchive),
          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _isConfigComplete ? Colors.blueAccent : Colors.grey,
                minimumSize: const Size(double.infinity, 50)
            ),
            onPressed: _isConfigComplete ? () => _masterFocus.requestFocus() : null,
            child: Text(_isConfigComplete ? "ACTIVATE TERMINAL" : "COMPLETE FORM",
                style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildTerminalView() {
    double boxProgress = (int.tryParse(_boxController.text) ?? 0) > 0
        ? _verifiedBoxCount / int.parse(_boxController.text) : 0.0;
    double looseProgress = (int.tryParse(_looseController.text) ?? 0) > 0
        ? _verifiedLooseCount / int.parse(_looseController.text) : 0.0;

    return BarcodeKeyboardListener(
      onBarcodeScanned: _onScanReceived,
      child: Column(
        children: [
          Row(
            children: [
              _progressCard("BOXES", "$_verifiedBoxCount/${_boxController.text}", boxProgress, Colors.blue, _isStandardMode),
              const SizedBox(width: 16),
              _progressCard("LOOSE", "$_verifiedLooseCount/${_looseController.text}", looseProgress, Colors.orange, !_isStandardMode),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _modeBtn("STANDARD", Colors.blue, _isStandardMode, () => setState(() => _isStandardMode = true)),
              _modeBtn("LOOSE", Colors.orange, !_isStandardMode, () => setState(() => _isStandardMode = false)),
            ],
          ),
          const SizedBox(height: 16),

          // --- NEW: PHOTO PICKER SECTION ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentImage == null ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _currentImage == null ? Colors.red : Colors.green),
            ),
            child: Row(
              children: [
                Icon(_currentImage == null ? Icons.image_not_supported : Icons.check_circle,
                    color: _currentImage == null ? Colors.red : Colors.green),
                const SizedBox(width: 12),
                Text(_currentImage == null ? "CAPTURE PHOTO (MANDATORY)" : "PHOTO READY",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                if (_currentImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_currentImage!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.file_upload, size: 16),
                  label: const Text("SELECT IMAGE", style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GWT and Qty Inputs: Only visible in Loose mode
          if (!_isStandardMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gwtController,
                      focusNode: _gwtFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Gross Weight (GWT)",
                        prefixIcon: const Icon(Icons.scale, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _looseQtyFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _looseQtyController,
                      focusNode: _looseQtyFocus,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Loose Qty",
                        prefixIcon: const Icon(Icons.format_list_numbered, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _masterFocus.requestFocus(),
                    ),
                  ),
                ],
              ),
            ),

          TextField(
            controller: _terminalController, focusNode: _masterFocus,
            enabled: _isConfigComplete && !_isUploading,
            onSubmitted: _onScanReceived,
            decoration: InputDecoration(
              filled: true, fillColor: _isConfigComplete ? Colors.white : Colors.grey[200],
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              hintText: _isUploading ? "UPLOADING PHOTO..." : (_isConfigComplete ? "SCAN NOW..." : "LOCKED"),
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("S.NO")),
          DataColumn(label: Text("TYPE")),
          DataColumn(label: Text("PHOTO")), // Added column
          DataColumn(label: Text("QTY")),
          DataColumn(label: Text("GWT")),
          DataColumn(label: Text("TIME")),
          DataColumn(label: Text("ACTION")),
        ],
        rows: List.generate(_liveItems.length, (index) {
          final item = _liveItems[index];
          return DataRow(cells: [
            DataCell(Text(item['sno'].toString())),
            DataCell(Text(item['type'], style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(
              item['imgUrl'] != null
                  ? IconButton(
                icon: const Icon(Icons.image, color: Colors.blue, size: 20),
                onPressed: () => _viewImage(item['imgUrl']),
              )
                  : const Text("No Image"),
            ),
            DataCell(Text(item['qty'])),
            DataCell(Text(item['gwt'].toString())),
            DataCell(Text(item['time'].toString().substring(11, 19))),
            DataCell(IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () => _deleteRow(index),
            )),
          ]);
        }),
      ),
    );
  }

  // --- NEW: VIEW IMAGE DIALOG ---
  void _viewImage(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              );
            }),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))
          ],
        ),
      ),
    );
  }

  // (Rest of the original search, history, excel, and print logic stays exactly the same)
  // ... (Full history view, exportToExcel, printProfessional etc here)

  Widget _buildFullHistoryView() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              const Text("DISPATCH ARCHIVE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Spacer(),
              SizedBox(
                width: 400,
                child: TextField(
                  onSubmitted: _searchHistory,
                  decoration: InputDecoration(
                    hintText: "Enter Bill or Pin...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historySearchResult == null) return const Center(child: Text("No data found"));

    return ListView.builder(
      itemCount: _historySearchResult!.docs.length,
      itemBuilder: (context, index) {
        var doc = _historySearchResult!.docs[index];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List items = data['items'] ?? [];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text("Bill: ${data['billNo']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text("PIN: ${data['customerPin']} | Items: ${items.length}", style: const TextStyle(fontSize: 11)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.green, size: 20),
                  onPressed: () => _exportToExcel(data),
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.blue, size: 20),
                  onPressed: () => _printProfessional(data),
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF8FAFC),
                child: DataTable(
                  headingRowHeight: 35,
                  columns: const [
                    DataColumn(label: Text("S.NO")),
                    DataColumn(label: Text("TYPE")),
                    DataColumn(label: Text("BARCODE")),
                    DataColumn(label: Text("GWT")),
                    DataColumn(label: Text("QTY")),
                    DataColumn(label: Text("DATE/TIME")),
                  ],
                  rows: items.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['sno'].toString())),
                      DataCell(Text(item['type'])),
                      DataCell(Text(item['barcode'])),
                      DataCell(Text(item['gwt'] ?? 'N/A')),
                      DataCell(Text(item['qty'] ?? 'N/A')),
                      DataCell(Text(item['time'] ?? 'N/A')),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _input(String l, TextEditingController c, IconData i) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        prefixIcon: Icon(i, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  );

  Widget _modeBtn(String t, Color c, bool a, VoidCallback o) => Expanded(
    child: InkWell(
      onTap: o,
      child: Container(
        height: 40, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: a ? c : Colors.white,
          border: Border.all(color: c),
        ),
        child: Text(t, style: TextStyle(color: a ? Colors.white : c, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    ),
  );

  Widget _progressCard(String title, String val, double progress, Color color, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : Colors.grey.shade200, width: active ? 2 : 1)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel(Map<String, dynamic> data) async {
    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Dispatch_Report'];

    sheetObject.appendRow([
      excel_pkg.TextCellValue('S.No'),
      excel_pkg.TextCellValue('Type'),
      excel_pkg.TextCellValue('Barcode'),
      excel_pkg.TextCellValue('GWT'),
      excel_pkg.TextCellValue('QTY'),
      excel_pkg.TextCellValue('Date/Time'),
    ]);

    List items = data['items'] ?? [];
    for (var item in items) {
      sheetObject.appendRow([
        excel_pkg.IntCellValue(item['sno'] ?? 0),
        excel_pkg.TextCellValue(item['type'] ?? ''),
        excel_pkg.TextCellValue(item['barcode'] ?? ''),
        excel_pkg.TextCellValue(item['gwt'] ?? 'N/A'),
        excel_pkg.TextCellValue(item['qty'] ?? 'N/A'),
        excel_pkg.TextCellValue(item['time'] ?? ''),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Bill_${data['billNo']}.xlsx');
    await file.writeAsBytes(fileBytes!);
    _showSnack("Excel saved to Documents", Colors.green);
  }

  Future<void> _printProfessional(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    List items = data['items'] ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("DISPATCH MANIFEST", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(children: [pw.Text("Bill No: "), pw.Text(data['billNo'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
              pw.Row(children: [pw.Text("Customer P/N: "), pw.Text(data['customerPin'])]),
              pw.Row(children: [pw.Text("Verified Date: "), pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['S.NO', 'TYPE', 'BARCODE', 'GWT', 'QTY','TIME'],
                data: items.map((i) => [i['sno'], i['type'], i['barcode'], i['gwt'] ?? 'N/A', i['qty'], i['time'] ?? 'N/A']).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}