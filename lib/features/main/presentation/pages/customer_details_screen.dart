
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/utils/routes_name.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textField.dart';

class CustomerDetailsPage extends StatefulWidget {
  const CustomerDetailsPage({super.key});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _pinController = TextEditingController();
  final _billController = TextEditingController();
  final _qtyController = TextEditingController();
  final _boxCountController = TextEditingController();
  final _looseBoxController = TextEditingController();

  final _pinFocus = FocusNode();
  final _billFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _boxFocus = FocusNode();
  final _looseFocus = FocusNode();

  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() => setState(() {}));
    _billController.addListener(() => setState(() {}));
    _qtyController.addListener(() => setState(() {}));
    _boxCountController.addListener(() => setState(() {}));
  }

  // FEATURE: CAMERA SCANNING LOGIC
  void _openCameraScanner(TextEditingController controller, FocusNode nextFocus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text("Scan with Camera"),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String code = barcodes.first.rawValue ?? "";
                    if (code.isNotEmpty) {
                      setState(() => controller.text = code);
                      Navigator.pop(context);
                      nextFocus.requestFocus();
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

  Future<void> _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return; // Prevents Crash

    setState(() => _isChecking = true);
    try {
      final String scannedPin = _pinController.text.trim();

      var fallbackQuery = await FirebaseFirestore.instance
          .collection('dispatches')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final bool alreadyExists = fallbackQuery.docs.any((doc) {
        final List items = doc.get('items') ?? [];
        return items.any((item) => item['barcode'] == scannedPin);
      });

      if (alreadyExists) {
        _showWarning("ALREADY SCANNED: This PIN exists in records!");
        _pinController.clear();
        _pinFocus.requestFocus();
      } else {
        if (mounted) {
          context.pushNamed(
            AppRoutes.scanScreen,
            queryParameters: {
              "billNo": _billController.text.trim(),
              "qty": _qtyController.text.trim(),
              "boxes": _boxCountController.text.trim(),
              "loose": _looseBoxController.text.trim(),
              "pin": scannedPin,
            },
          );
        }
      }
    } catch (e) {
      _showWarning("Database Error: Verification failed.");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dispatch Entry", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.scanHistory),
            icon: const Icon(Icons.history_rounded, color: Colors.blueAccent),
          )
        ],
      ),
      body: BarcodeKeyboardListener(
        onBarcodeScanned: (code) {
          if (_pinController.text.isEmpty) {
            _pinController.text = code;
            _billFocus.requestFocus();
          } else if (_billController.text.isEmpty) {
            _billController.text = code;
            _qtyFocus.requestFocus();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ScannerTextField(
                  label: "Customer Pin", icon: Icons.pin_drop,
                  controller: _pinController, focusNode: _pinFocus,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _openCameraScanner(_pinController, _billFocus),
                  ),
                  onFieldSubmitted: (_) => _billFocus.requestFocus(),
                  validator: (v) => v!.isEmpty ? "PIN Required" : null,
                ),
                ScannerTextField(
                  label: "Invoice / Bill No", icon: Icons.receipt_long,
                  controller: _billController, focusNode: _billFocus,
                  enabled: _pinController.text.isNotEmpty,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _openCameraScanner(_billController, _qtyFocus),
                  ),
                  onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                  validator: (v) => v!.isEmpty ? "Bill No Required" : null,
                ),
                ScannerTextField(
                  label: "QTY", icon: Icons.inventory_2,
                  controller: _qtyController, focusNode: _qtyFocus,
                  enabled: _billController.text.isNotEmpty,
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (_) => _boxFocus.requestFocus(),
                  validator: (v) => v!.isEmpty ? "Qty Required" : null,
                ),
                ScannerTextField(
                  label: "Nos Of Box", icon: Icons.card_giftcard,
                  controller: _boxCountController, focusNode: _boxFocus,
                  enabled: _qtyController.text.isNotEmpty,
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (_) => _looseFocus.requestFocus(),
                  validator: (v) => v!.isEmpty ? "Box count Required" : null,
                ),
                ScannerTextField(
                  label: "Loose Boxes", icon: Icons.unarchive,
                  controller: _looseBoxController, focusNode: _looseFocus,
                  enabled: _boxCountController.text.isNotEmpty,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Enter 0 if none" : null,
                ),
                const SizedBox(height: 30),
                if (_isChecking)
                  const CircularProgressIndicator()
                else
                  CustomButton(
                    label: "PROCEED",
                    width: double.infinity,
                    onPressed: _validateAndProceed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}