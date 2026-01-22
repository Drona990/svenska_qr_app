import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constant/Endpoints.dart';

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
  final _looseQtyController = TextEditingController();
  final FocusNode _gwtFocus = FocusNode();
  final FocusNode _looseQtyFocus = FocusNode();

  final List<Map<String, dynamic>> _liveItems = [];
  bool _isStandardMode = true;
  bool _isSaving = false;
  bool _isCheckingBill = false;
  File? _currentImage;
  final ImagePicker _picker = ImagePicker();

  final FocusNode _masterFocus = FocusNode();
  final TextEditingController _terminalController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Archive State
  List<dynamic>? _historySearchResult;
  bool _isHistoryLoading = false;
  bool _showHistoryOnly = false;

  int get _verifiedBoxCount => _liveItems.where((item) => item['type'] == 'BOX').length;
  int get _verifiedLooseCount => _liveItems.where((item) => item['type'] == 'LOOSE').length;

  bool get _isConfigComplete =>
      _pinController.text.isNotEmpty && _billController.text.isNotEmpty &&
          _qtyController.text.isNotEmpty && _boxController.text.isNotEmpty && _looseController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    List<TextEditingController> ctrls = [_pinController, _billController, _qtyController, _boxController, _looseController, _gwtController, _looseQtyController];
    for (var c in ctrls) { c.addListener(() => setState(() {})); }
  }

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Date N/A";
    try {
      DateTime dt = DateTime.parse(rawDate);
      return DateFormat('dd-MM-yyyy  |  hh:mm a').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _checkBillAndActivate() async {
    setState(() => _isCheckingBill = true);
    try {
      final res = await GetIt.I<ApiClient>().get('/api/dispatches/', queryParams: {'search': _billController.text.trim()});
      List results = res.data['data'] ?? [];
      bool exists = results.any((d) => d['bill_no'] == _billController.text.trim());

      if (exists) {
        _playAlert(true);
        _showSnack("ERROR: Bill No already exists!", Colors.red);
      } else {
        _masterFocus.requestFocus();
        _showSnack("Terminal Ready", Colors.blue);
      }
    } catch (e) { _showSnack("Check failed", Colors.orange); }
    finally { setState(() => _isCheckingBill = false); }
  }

  Future<void> _saveToBackend() async {
    setState(() => _isSaving = true);
    try {
      // 1. Prepare Metadata JSON
      List<Map<String, dynamic>> itemsMeta = _liveItems.map((item) {
        return {
          'sno': item['sno'],
          'type': item['type'],
          'barcode': item['barcode'],
          'qty': item['qty'],
          'gwt': item['gwt'],
        };
      }).toList();

      dio_lib.FormData formData = dio_lib.FormData.fromMap({
        'billNo': _billController.text,
        'customerPin': _pinController.text,
        'totalQty': _qtyController.text,
        'items_meta': jsonEncode(itemsMeta),
      });

      // 3. Attach local images with indexed keys image_0, image_1...
      for (int i = 0; i < _liveItems.length; i++) {
        if (_liveItems[i]['localFile'] != null) {
          formData.files.add(MapEntry(
            'image_$i',
            await dio_lib.MultipartFile.fromFile(
                _liveItems[i]['localFile'].path,
                filename: 'item_$i.jpg'
            ),
          ));
        }
      }

      // 4. Send via registered ApiClient
      final response = await GetIt.I<ApiClient>().post(
          '/api/dispatches/',
          data: formData
      );

      if (response.statusCode == 201) {
        _showSnack("Dispatch Saved to Local Server!", Colors.green);
        _resetStation();
      }
    } catch (e) {
      _showSnack("Failed to reach server", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _searchHistory(String q) async {
    setState(() { _isHistoryLoading = true; _historySearchResult = null; });
    try {
      final res = await GetIt.I<ApiClient>().get('/api/dispatches/', queryParams: {'search': q.trim()});
      setState(() { _historySearchResult = res.data['data']; _isHistoryLoading = false; });
    } catch (e) { setState(() => _isHistoryLoading = false); }
  }

  void _onScanReceived(String code) async {
    final scannedCode = code.trim();
    if (scannedCode.isEmpty || _isSaving || !_isConfigComplete) return;

    if (_currentImage == null) {
      _playAlert(true);
      _showSnack("REQUIRED: Please select item image first!", Colors.red);
      return;
    }

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
        setState(() {
          _liveItems.insert(0, {
            'sno': _liveItems.length + 1,
            'barcode': scannedCode,
            'type': _isStandardMode ? 'BOX' : 'LOOSE',
            'qty': _isStandardMode ? _qtyController.text : _looseQtyController.text,
            'gwt': _isStandardMode ? 'STD' : _gwtController.text,
            'localFile': _currentImage,
            'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          });
          _currentImage = null;
          if (!_isStandardMode) {
            _gwtController.clear();
            _looseQtyController.clear();
          }
        });
        _playAlert(false);

        if (_verifiedBoxCount == (int.tryParse(_boxController.text) ?? 0) &&
            _verifiedLooseCount == (int.tryParse(_looseController.text) ?? 0)) {
          _saveToBackend();
        }
      } else {
        _showSnack("Verification Completed!", Colors.orange);
      }
    } else {
      _playAlert(true);
      _showSnack("Invalid Scan: $scannedCode", Colors.red);
    }
    _terminalController.clear();
    _masterFocus.requestFocus();
  }


  // --- UI ---

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
                    child: _showHistoryOnly ? _buildFullHistoryView(): _buildMainStation(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStation() => Row(children: [
    Expanded(flex: 3, child: _buildEntryForm()),
    const SizedBox(width: 24),
    Expanded(flex: 7, child: _buildTerminalView()),
  ]);

  Widget _buildSidebar() => Container(
    width: 70, color: const Color(0xFF0F172A),
    child: Column(children: [
      const SizedBox(height: 30), const Icon(Icons.precision_manufacturing, color: Colors.blueAccent),
      const Spacer(),
      IconButton(icon: Icon(Icons.dashboard, color: !_showHistoryOnly ? Colors.blueAccent : Colors.white24), onPressed: () => setState(() => _showHistoryOnly = false)),
      IconButton(icon: Icon(Icons.history, color: _showHistoryOnly ? Colors.blueAccent : Colors.white24), onPressed: () => setState(() => _showHistoryOnly = true)),
      const SizedBox(height: 30),
    ]),
  );

  Widget _buildHeader() => Container(
    height: 60, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(children: [
      Text(_showHistoryOnly ? "ARCHIVE" : "DISPATCH WORK STATION", style: const TextStyle(fontWeight: FontWeight.w900)),
      const Spacer(), const Icon(Icons.circle, color: Colors.green, size: 12),
      const SizedBox(width: 8), const Text("ONLINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );

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
            style: ElevatedButton.styleFrom(backgroundColor: _isConfigComplete ? Colors.blueAccent : Colors.grey, minimumSize: const Size(double.infinity, 50)),
            onPressed: (_isConfigComplete && !_isCheckingBill) ? _checkBillAndActivate : null,
            child: _isCheckingBill ? const CircularProgressIndicator(color: Colors.white) : const Text("ACTIVATE", style: TextStyle(color: Colors.white)),
          )

        ],
      ),
    );
  }

  Widget _buildTerminalView() => BarcodeKeyboardListener(
    onBarcodeScanned: _onScanReceived,
    child: Column(children: [
      Row(children: [
        _progressCard("BOXES", "$_verifiedBoxCount/${_boxController.text}", Colors.blue, _isStandardMode),
        const SizedBox(width: 16),
        _progressCard("LOOSE", "$_verifiedLooseCount/${_looseController.text}", Colors.orange, !_isStandardMode),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        _modeBtn("STANDARD", Colors.blue, _isStandardMode, () => setState(() => _isStandardMode = true)),
        _modeBtn("LOOSE", Colors.orange, !_isStandardMode, () => setState(() => _isStandardMode = false)),
      ]),
      const SizedBox(height: 16),
      _buildPhotoPicker(),
      if (!_isStandardMode) _buildLooseInputs(),
      const SizedBox(height: 16),
      _buildScanField(),
      const SizedBox(height: 16),
      Expanded(
        child: Container(
          width: double.infinity,
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildDataTable(),
        ),
      )
    ]),
  );

  Widget _buildPhotoPicker() => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _currentImage == null ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _currentImage == null ? Colors.red : Colors.green)),
    child: Row(children: [
      Icon(_currentImage == null ? Icons.camera_alt : Icons.check_circle, color: _currentImage == null ? Colors.red : Colors.green),
      const SizedBox(width: 12), Text(_currentImage == null ? "CAPTURE PHOTO" : "READY"),
      const Spacer(),
      if (_currentImage != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_currentImage!, width: 40, height: 40, fit: BoxFit.cover)),
      const SizedBox(width: 10),
      ElevatedButton(onPressed: _pickImage, child: const Text("PHOTO")),
    ]),
  );

  Widget _buildScanField() => TextField(
    controller: _terminalController, focusNode: _masterFocus, enabled: _isConfigComplete && !_isSaving, onSubmitted: _onScanReceived,
    decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: _isSaving ? "SAVING..." : "SCAN NOW", prefixIcon: const Icon(Icons.qr_code_scanner), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
  );

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("S.NO")),
          DataColumn(label: Text("TYPE")),
          DataColumn(label: Text("PHOTO")),
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
            DataCell(item['localFile'] != null ? const Icon(Icons.image, color: Colors.blue) : const Text("MISSING")),
            DataCell(Text(item['qty'])),
            DataCell(Text(item['gwt'].toString())),
            DataCell(Text(item['time'].toString().substring(11, 19))),
            DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _liveItems.removeAt(index)))),
          ]);
        }),
      ),
    );
  }

  Widget _buildFullHistoryView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slate 50
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Area
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Central Archive",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  Text("Review and audit previous dispatch cycles",
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400)),
                ],
              ),
              const Spacer(),
              _buildSearchBar(),
            ],
          ),
          const SizedBox(height: 32),

          // Main History Area
          Expanded(
            child: _isHistoryLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _historySearchResult == null || _historySearchResult!.isEmpty
                ? _buildEmptyState()
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: List of Dispatches
                Expanded(flex: 4, child: _buildHistoryList()),
                const SizedBox(width: 24),
                // Right Side: Details of Selected Dispatch (Optional / Implementation logic)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search, size: 80, color: Colors.blueGrey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
              "No Dispatches Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))
          ),
          const SizedBox(height: 8),
          const Text(
              "Try searching with a different Bill Number or Customer PIN",
              style: TextStyle(color: Colors.grey)
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        onSubmitted: _searchHistory,
        decoration: InputDecoration(
          hintText: "Search by Bill No or Customer PIN...",
          hintStyle: TextStyle(color: Colors.blueGrey.shade200, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      itemCount: _historySearchResult!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        var data = _historySearchResult![index];
        List items = data['items'] ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent),
            ),
            title: Text(
              "BILL #${data['bill_no']}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: PIN and Item Count
                Text(
                  "PIN: ${data['customer_pin']}  •  ${items.length} Items Verified",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                // Line 2: Date and Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(data['created_at']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _buildStatusBadge(data['status'] ?? "Verified"),
            children: [
              _buildItemGrid(items),
            ],
          ),

        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildItemGrid(List items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: const [
                SizedBox(width: 35, child: Center(child: Text("SNO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                SizedBox(width: 50, child: Center(child: Text("IMG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 3, child: Center(child: Text("BARCODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 2, child: Center(child: Text("TYPE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 2, child: Center(child: Text("GWT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 2, child: Center(child: Text("QTY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 3, child: Center(child: Text("TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
              ],
            ),
          ),

          // Item Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, idx) {
              final item = items[idx];

              String formattedDate = "-";
              String formattedTime = "";
              if (item['scanned_at'] != null) {
                try {
                  DateTime dt = DateTime.parse(item['scanned_at']);
                  formattedDate = DateFormat('dd-MM-yyyy').format(dt);
                  formattedTime = DateFormat('hh:mm a').format(dt);
                } catch (e) {
                  formattedDate = "Error";
                }
              }

              return InkWell(
                onTap: () => _viewImage(item['image']),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // SNO - Centered
                      SizedBox(width: 35, child: Center(child: Text("${item['sno']}", style: const TextStyle(fontSize: 11, color: Color(0xFF475569))))),

                      // Thumbnail - Centered
                      SizedBox(
                        width: 50,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                "${Endpoints.baseUrl}${item['image']}",
                                width: 32, height: 32, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 18, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Barcode - Centered
                      Expanded(
                          flex: 3,
                          child: Center(child: Text(item['barcode'] ?? "-", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueAccent)))
                      ),

                      // Type Badge - Centered
                      Expanded(
                          flex: 2,
                          child: Center(child: _buildTypeBadge(item['item_type'] ?? "N/A"))
                      ),

                      // GWT - Centered
                      Expanded(
                          flex: 2,
                          child: Center(child: Text(item['gwt'] ?? "STD", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))))
                      ),

                      // Qty - Centered
                      Expanded(
                          flex: 2,
                          child: Center(child: Text("${item['qty']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))
                      ),

                      // Scanned At - Centered
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(formattedDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            Text(formattedTime, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = type.toUpperCase() == 'BOX' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.04)),
      ),
      child: Text(
        type,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _viewImage(String relativeUrl) {
    final String fullUrl = relativeUrl.startsWith('http')
        ? relativeUrl
        : "${Endpoints.baseUrl}$relativeUrl";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Item Verification Photo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                // Show progress while downloading from Django
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                // Handle 404 or Network issues
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.red, size: 40),
                      SizedBox(height: 10),
                      Text("Image not found on server", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.grey[50],
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String l, TextEditingController c, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))));
  Widget _modeBtn(String t, Color c, bool a, VoidCallback o) => Expanded(child: InkWell(onTap: o, child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: a ? c : Colors.white, border: Border.all(color: c)), child: Text(t, style: TextStyle(color: a ? Colors.white : c, fontWeight: FontWeight.bold)))));
  Widget _progressCard(String t, String v, Color c, bool a) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: a ? c : Colors.grey.shade200, width: a ? 2 : 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10)), Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c))])));
  Widget _buildLooseInputs() => Padding(padding: const EdgeInsets.only(top: 16), child: Row(children: [Expanded(child: TextField(controller: _gwtController, focusNode: _gwtFocus, decoration: const InputDecoration(labelText: "GWT", border: OutlineInputBorder()))), const SizedBox(width: 10), Expanded(child: TextField(controller: _looseQtyController, focusNode: _looseQtyFocus, decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder())))]));

  void _resetStation() { _pinController.clear(); _billController.clear(); _qtyController.clear(); _boxController.clear(); _looseController.clear(); _liveItems.clear(); _terminalController.clear(); _currentImage = null; setState(() {}); _masterFocus.requestFocus(); }
  void _playAlert(bool isError) { _audioPlayer.play(AssetSource(isError ? 'sound/beep-warning.mp3' : 'sound/beep.mp3')); if (isError) HapticFeedback.heavyImpact(); }
  void _showSnack(String m, Color c) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c)); }
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: (Platform.isWindows) ? ImageSource.gallery : ImageSource.camera);
    if (image != null) setState(() => _currentImage = File(image.path));
  }
}
