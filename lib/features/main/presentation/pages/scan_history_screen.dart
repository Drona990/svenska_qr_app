
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/network/api_client.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<dynamic>? _historyList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus for hardware scanner support
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  // --- BUSINESS LOGIC ---

  void _searchData(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _historyList = null;
    });

    try {
      final response = await GetIt.I<ApiClient>().get(
        '/api/dispatches/',
        queryParams: {'search': query.trim()},
      );

      setState(() {
        _historyList = response.data['data'];
        _isLoading = false;
      });

      if (_historyList == null || _historyList!.isEmpty) {
        _showSnackBar("No records found for: $query", Colors.orange);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Server Error: $e", Colors.red);
    }
    _searchFocus.requestFocus();
  }

  void _viewImage(String? relativeUrl) {
    if (relativeUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                "http://10.11.35.96:8000$relativeUrl", // Use your server base
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          ],
        ),
      ),
    );
  }


  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Archive Explorer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.description_rounded, color: Colors.green)),
        ],
      ),
      body: BarcodeKeyboardListener(
        onBarcodeScanned: _searchData,
        child: Column(
          children: [
            _buildProfessionalSearchHeader(),
            if (_isLoading) const LinearProgressIndicator(color: Colors.blueAccent),
            Expanded(child: _buildHistoryContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        decoration: InputDecoration(
          hintText: "Scan Bill, PIN or Barcode",
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.blueAccent),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent), onPressed: _openCameraScanner),
              IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => _searchData(_searchController.text)),
            ],
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onSubmitted: _searchData,
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_historyList == null || _historyList!.isEmpty) return _emptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyList!.length,
      itemBuilder: (context, billIndex) {
        final data = _historyList![billIndex];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text("BILL: ${data['bill_no']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("PIN: ${data['customer_pin']} • Date: ${data['created_at'].toString().substring(0, 10)}"),
            children: [_buildProfessionalTable(data['items'] ?? [])],
          ),
        );
      },
    );
  }

/*
  Widget _buildProfessionalTable(List items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFFBFDFF), borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('SNO', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('BARCODE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GWT', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PHOTO', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold))),

          ],
          rows: items.map((item) => DataRow(cells: [
            DataCell(Text(item['sno']?.toString() ?? '-')),
            DataCell(Text(item['barcode'] ?? '-')),
            DataCell(Text(item['item_type'] ?? '-')),
            DataCell(Text(item['gwt'] ?? '-')),
            DataCell(Text(item['qty']?.toString() ?? '0')),
            DataCell(IconButton(
              icon: const Icon(Icons.image_search_rounded, color: Colors.blueAccent),
              onPressed: () => _viewImage(item['image']),
            )),
            DataCell(Text(item['created_at']?.toString() ?? '0')),

          ])).toList(),
        ),
      ),
    );
  }
*/


  Widget _buildProfessionalTable(List items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 45,
          dataRowMaxHeight: 60, // Increased height to accommodate two-line date/time
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 20,
          border: TableBorder(
            verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          columns: const [
            DataColumn(label: Text('SNO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('BARCODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('GWT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('PHOTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: items.map((item) {
            // Parse the date string safely
            String rawDate = item['scanned_at']?.toString() ?? '';
            String formattedDate = '-';
            String formattedTime = '';

            if (rawDate.isNotEmpty && rawDate != '0') {
              try {
                DateTime dt = DateTime.parse(rawDate);
                formattedDate = DateFormat('dd-MM-yyyy').format(dt);
                formattedTime = DateFormat('hh:mm a').format(dt);
              } catch (e) {
                formattedDate = rawDate; // Fallback to raw string if parsing fails
              }
            }

            return DataRow(cells: [
              DataCell(Text(item['sno']?.toString() ?? '-')),
              DataCell(Text(item['barcode'] ?? '-', style: const TextStyle(fontSize: 12))),
              // Badge UI for Item Type
              DataCell(_buildTypeBadge(item['item_type']?.toString() ?? 'N/A')),
              DataCell(Text(item['gwt'] ?? 'STD', style: const TextStyle(fontSize: 12))),
              DataCell(Text(item['qty']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(IconButton(
                icon: const Icon(Icons.image_search_rounded, color: Colors.blueAccent, size: 22),
                onPressed: () => _viewImage(item['image']),
              )),
              // Two-line Date and Time display
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formattedDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  if (formattedTime.isNotEmpty)
                    Text(formattedTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

// Helper for professional Type Badge
  Widget _buildTypeBadge(String type) {
    Color color = type.toUpperCase() == 'BOX' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }


  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: MobileScanner(
          onDetect: (capture) {
            final String code = capture.barcodes.first.rawValue ?? "";
            if (code.isNotEmpty) {
              Navigator.pop(context);
              _searchController.text = code;
              _searchData(code);
            }
          },
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.manage_search_rounded, size: 80, color: Colors.grey.shade300),
        const Text("System Ready", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    ),
  );

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
  );
}