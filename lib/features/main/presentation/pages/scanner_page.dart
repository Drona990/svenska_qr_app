import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ScannerScreen extends StatefulWidget {
  final String billNo, targetPin, qty, loose;
  final int totalBoxes;

  const ScannerScreen({
    super.key,
    required this.billNo,
    required this.targetPin,
    required this.totalBoxes,
    required this.qty,
    required this.loose,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _scanController = TextEditingController();
  final TextEditingController _gwtController = TextEditingController();
  final TextEditingController _looseQtyController = TextEditingController();

  final FocusNode _terminalFocus = FocusNode();
  final FocusNode _gwtFocus = FocusNode();
  final FocusNode _looseQtyFocus = FocusNode();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _verifiedTableData = [];
  File? _currentImage;
  bool _isStandardMode = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _terminalFocus.requestFocus());
  }

  @override
  void dispose() {
    _scanController.dispose();
    _gwtController.dispose();
    _looseQtyController.dispose();
    _terminalFocus.dispose();
    _gwtFocus.dispose();
    _looseQtyFocus.dispose();
    super.dispose();
  }

  int get _verifiedBoxCount => _verifiedTableData.where((item) => item['type'] == 'BOX').length;
  int get _verifiedLooseCount => _verifiedTableData.where((item) => item['type'] == 'LOOSE').length;

  // --------------------------------------------------------------------------
  // LOGIC: IMAGE, SCANNING & DELETE (EXACTLY AS REQUESTED)
  // --------------------------------------------------------------------------
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 40);
    if (photo != null) setState(() => _currentImage = File(photo.path));
  }

  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => _isUploading = true);
      String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('dispatch_photos').child(fileName);
      TaskSnapshot snapshot = await ref.putFile(image);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showWarning("Upload Failed", Colors.red);
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _onScanReceived(String code) async {
    final scannedCode = code.trim();
    if (scannedCode.isEmpty || _isSaving || _isUploading) return;

    if (_currentImage == null) {
      _playAlert(true);
      _showWarning("REQUIRED: Take photo first!", Colors.red);
      return;
    }

    if (!_isStandardMode && (_gwtController.text.isEmpty || _looseQtyController.text.isEmpty)) {
      _playAlert(true);
      _showWarning("REQUIRED: Enter GWT and Qty!", Colors.red);
      _gwtFocus.requestFocus();
      return;
    }

    if (scannedCode == widget.targetPin) {
      int target = _isStandardMode ? widget.totalBoxes : int.parse(widget.loose);
      int current = _isStandardMode ? _verifiedBoxCount : _verifiedLooseCount;

      if (current < target) {
        String? url = await _uploadImage(_currentImage!);
        if (url == null) return;

        setState(() {
          _verifiedTableData.insert(0, {
            'sno': _verifiedTableData.length + 1,
            'barcode': scannedCode,
            'type': _isStandardMode ? 'BOX' : 'LOOSE',
            'gwt': _isStandardMode ? '' : _gwtController.text.trim(),
            'qty': _isStandardMode ? widget.qty : _looseQtyController.text.trim(),
            'imgUrl': url,
            'time': DateFormat('HH:mm:ss').format(DateTime.now()),
          });
          _currentImage = null;
          _gwtController.clear();
          _looseQtyController.clear();
        });
        _playAlert(false);
        if (_verifiedBoxCount == widget.totalBoxes && _verifiedLooseCount == int.parse(widget.loose)) _saveToFirebase();
      }
    } else {
      _playAlert(true);
      _showWarning("Invalid Scan!", Colors.red);
    }
    _scanController.clear();
    _terminalFocus.requestFocus();
  }

  // --------------------------------------------------------------------------
  // UI BUILD: SLIVER ARCHITECTURE TO PREVENT 100PX OVERFLOW
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    bool isComplete = _verifiedBoxCount == widget.totalBoxes && _verifiedLooseCount == int.parse(widget.loose);

    return PopScope(
      canPop: isComplete,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("Invoice: ${widget.billNo}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BarcodeKeyboardListener(
          onBarcodeScanned: _onScanReceived,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildStatusBar(),
                    _buildModeToggle(),
                    _buildPhotoSection(),
                    if (!_isStandardMode) _buildLooseInputs(),
                    _buildProfessionalTerminal(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              SliverFillRemaining(
                hasScrollBody: true,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _buildDataTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTerminal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: _scanController,
        focusNode: _terminalFocus,
        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: _isUploading ? "UPLOADING..." : "SCAN QR CODE",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
          suffixIcon: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              onPressed: _openCameraScanner
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: _onScanReceived,
      ),
    );
  }

  Widget _buildLooseInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _miniInput("GWT", _gwtController, _gwtFocus, Icons.scale)),
          const SizedBox(width: 10),
          Expanded(child: _miniInput("QTY", _looseQtyController, _looseQtyFocus, Icons.inventory)),
        ],
      ),
    );
  }

  Widget _miniInput(String label, TextEditingController controller, FocusNode node, IconData icon) {
    return TextField(
      controller: controller,
      focusNode: node,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12,fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, size: 18, color: Colors.blueAccent), // Blue Accent Icon
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _takePhoto,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _currentImage == null ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _currentImage == null ? Colors.red : Colors.green),
          ),
          child: Row(
            children: [
              Icon(_currentImage == null ? Icons.add_a_photo : Icons.check_circle, color: _currentImage == null ? Colors.red : Colors.green),
              const SizedBox(width: 15),
              Text(_currentImage == null ? "CAPTURE PHOTO (MANDATORY)" : "PHOTO READY", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              if (_currentImage != null) ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.file(_currentImage!, width: 40, height: 40, fit: BoxFit.cover)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('S.NO',style: TextStyle(fontWeight: FontWeight.bold),)),
              DataColumn(label: Text('TYPE',style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('GWT',style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('QTY',style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('PHOTO',style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ACTION',style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(_verifiedTableData.length, (index) {
              final item = _verifiedTableData[index];
              return DataRow(cells: [
                DataCell(Text(item['sno'].toString())),
                DataCell(Text(item['type'])),
                DataCell(Text(item['gwt'])),
                DataCell(Text(item['qty'])),
                DataCell(IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => _viewImage(item['imgUrl']))),
                DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRow(index))),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildStatusBar() => Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_stat("BOX", "$_verifiedBoxCount/${widget.totalBoxes}"), _stat("LOOSE", "$_verifiedLooseCount/${widget.loose}"), _stat("TOTAL QTY", widget.qty)]));
  Widget _stat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white54, fontSize: 10,fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]);
  Widget _buildModeToggle() => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [_toggle("STANDARD", _isStandardMode, () => setState(() => _isStandardMode = true), Colors.blue), _toggle("LOOSE", !_isStandardMode, () => setState(() => _isStandardMode = false), Colors.orange)]));
  Widget _toggle(String l, bool a, VoidCallback o, Color c) => Expanded(child: InkWell(onTap: o, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: a ? c : Colors.white, border: Border.all(color: c)), child: Center(child: Text(l, style: TextStyle(color: a ? Colors.white : c, fontWeight: FontWeight.bold, fontSize: 11))))));

  void _openCameraScanner() {
    showModalBottomSheet(context: context, builder: (context) => SizedBox(height: 400, child: MobileScanner(onDetect: (capture) {
      if (capture.barcodes.isNotEmpty) {
        Navigator.pop(context);
        _onScanReceived(capture.barcodes.first.rawValue ?? "");
      }
    })));
  }

  void _viewImage(String url) => showDialog(context: context, builder: (_) => AlertDialog(content: Image.network(url), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))]));

  Future<void> _deleteRow(int index) async {
    String? url = _verifiedTableData[index]['imgUrl'];
    if (url != null) {
      try { await FirebaseStorage.instance.refFromURL(url).delete(); } catch (_) {}
    }
    setState(() {
      _verifiedTableData.removeAt(index);
      for (int i = 0; i < _verifiedTableData.length; i++) {
        _verifiedTableData[i]['sno'] = _verifiedTableData.length - i;
      }
    });
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('dispatches').add({
        'billNo': widget.billNo,
        'customerPin': widget.targetPin,
        'timestamp': FieldValue.serverTimestamp(),
        'items': _verifiedTableData,
        'status': 'Verified',
      });
      _showWarning("DISPATCH SAVED!", Colors.green);
    } catch (e) {
      _showWarning("Save Error", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _playAlert(bool e) => _audioPlayer.play(AssetSource(e ? 'sound/beep-warning.mp3' : 'sound/beep.mp3'));
  void _showWarning(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}