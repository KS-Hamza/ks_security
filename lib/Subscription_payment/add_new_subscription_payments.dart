import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../api_services.dart';

import 'package:http/http.dart' as http;

import '../encryption.dart';

class AddNewSubscriptionPayments extends StatefulWidget {
  final String subscriptionId;

  const AddNewSubscriptionPayments({Key? key, required this.subscriptionId}) : super(key: key);

  @override
  _AddNewSubscriptionPaymentsState createState() => _AddNewSubscriptionPaymentsState();
}

class _AddNewSubscriptionPaymentsState extends State<AddNewSubscriptionPayments> {
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController subscriptionCostController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  String? selectedCurrencyId;
  String? selectedPaymentMethodId;
  String? selectedFile;
  File? important_attachments;

  List<Map<String, String>> currencyOptions = [];
  List<Map<String, String>> paymentMethodOptions = [];

  final ApiServices apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper();

  Widget? imageWidget;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final Map<String, dynamic>? currenciesData = await apiServices.fetchCurrencies();
      if (currenciesData != null && currenciesData['data'] != null) {
        setState(() {
          currencyOptions = List<Map<String, String>>.from(
              currenciesData['data'].map((currency) => {
                'id': currency['id'].toString(),
                'name': currency['name'].toString(),
              }));
        });
      }

      final Map<String, dynamic>? paymentMethodsData = await apiServices.fetchPaymentMethods();
      if (paymentMethodsData != null && paymentMethodsData['data'] != null) {
        setState(() {
          paymentMethodOptions = List<Map<String, String>>.from(
              paymentMethodsData['data'].map((method) => {
                'id': method['id'].toString(),
                'name': method['name'].toString(),
              }));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load currencies or payment methods.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePayment() async {
    try {
      // Encrypt sensitive fields
      String encryptedCost = encryptionHelper.encrypt(subscriptionCostController.text);
      String encryptedRemarks = encryptionHelper.encrypt(remarksController.text);

      // Prepare form data
      final Map<String, String> formData = {
        'subscription_id': widget.subscriptionId,
        'start_date': startDateController.text,
        'end_date': endDateController.text,
        'subscription_cost': encryptedCost,
        'currency_id': selectedCurrencyId ?? '',
        'payment_method_id': selectedPaymentMethodId ?? '',
        'remarks': encryptedRemarks,
      };

      // Handle file attachment with file path and Base64 encoding
      if (selectedFile != null && selectedFile!.isNotEmpty) {
        File importantAttachments = File(selectedFile!); // Use the file path here

        if (importantAttachments.existsSync()) {
          print('File selected: ${importantAttachments.path}'); // Debug: Print the file path

          // Read the file bytes and encode to Base64
          final base64File = base64Encode(importantAttachments.readAsBytesSync());
          formData['important_attachments'] = base64File; // Add Base64 to form data

          // Debug: Print Base64 string
          print('Base64 File: $base64File');
        } else {
          print('Error: File does not exist at path: ${importantAttachments.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file does not exist or is inaccessible.')),
          );
          return;
        }
      } else {
        print('No file selected for upload.');
      }

      // Debug: Print the entire form data
      print("Form Data being sent to API: $formData");

      // API Call to save payment
      bool success = await apiServices.addNewSubscriptionPayments(formData, null);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription payment added successfully!')),
        );
        _resetFields(); // Reset the fields after successful submission
      } else {
        print("Error: API returned unsuccessful status.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add subscription payment')),
        );
      }
    } catch (e) {
      print("Exception occurred during file upload or API call: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding subscription payment: $e')),
      );
    }
  }




  void _resetFields() {
    startDateController.clear();
    endDateController.clear();
    subscriptionCostController.clear();
    remarksController.clear();
    setState(() {
      selectedCurrencyId = null;
      selectedPaymentMethodId = null;
      selectedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Subscription Payment",
          style: GoogleFonts.roboto(fontSize: 23, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Subscription ID"),
                    Text(widget.subscriptionId, style: GoogleFonts.roboto(fontSize: 18, color: Colors.black)),
                    const SizedBox(height: 20),
                    _buildLabel("Start Date"),
                    _buildDateField("Start Date", startDateController, Icons.calendar_today),
                    const SizedBox(height: 20),
                    _buildLabel("End Date"),
                    _buildDateField("End Date", endDateController, Icons.calendar_today),
                    const SizedBox(height: 20),
                    _buildLabel("Subscription Cost"),
                    _buildTextField(subscriptionCostController, "Enter Subscription Cost", Icons.attach_money),
                    const SizedBox(height: 20),
                    _buildLabel("Currency"),
                    _buildDropdownField(currencyOptions, selectedCurrencyId, (newValue) {
                      setState(() {
                        selectedCurrencyId = newValue;
                      });
                    }),
                    const SizedBox(height: 20),
                    _buildLabel("Payment Method"),
                    _buildDropdownField(paymentMethodOptions, selectedPaymentMethodId, (newValue) {
                      setState(() {
                        selectedPaymentMethodId = newValue;
                      });
                    }),
                    const SizedBox(height: 20),
                    _buildLabel("Remarks"),
                    _buildTextField(remarksController, "Enter Remarks", Icons.text_snippet, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildLabel("important_attachments"),
                    _buildFilePickerField(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildGradientButtonRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(label, style: GoogleFonts.roboto(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
  );

  Widget _buildCard(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 5))],
    ),
    child: child,
  );

  Widget _buildDateField(String label, TextEditingController controller, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
        fillColor: Colors.white.withOpacity(0.9),
        filled: true,
        prefixIcon: Icon(icon, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
      ),
      style: GoogleFonts.roboto(color: Colors.black),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
          });
        }
      },
    ),
  );

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
            fillColor: Colors.white.withOpacity(0.9),
            filled: true,
            prefixIcon: Icon(icon, color: Colors.black),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
          ),
          style: GoogleFonts.roboto(color: Colors.black),
        ),
      );

  Widget _buildDropdownField(List<Map<String, String>> options, String? selectedValue, Function(String?) onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            fillColor: Colors.white.withOpacity(0.9),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(value: option['id'], child: Text(option['name']!, style: GoogleFonts.roboto(color: Colors.black)));
          }).toList(),
          onChanged: onChanged,
          style: GoogleFonts.roboto(color: Colors.black),
        ),
      );

  Widget _buildFilePickerField() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      children: [
        Expanded(
          child: Text(selectedFile ?? 'No file chosen', style: GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null) {
              setState(() {
                selectedFile = result.files.single.path;
              });
              print('Selected file path: $selectedFile'); // Debug: Print the file path
            }
          },
          child: const Text('Choose File'),
        ),
      ],
    ),
  );

  Widget _buildGradientButtonRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildGradientButton(
        label: 'Save',
        onPressed: _savePayment,
        colors: [Colors.lightBlueAccent, Colors.blueAccent],
      ),
      _buildGradientButton(
        label: 'Reset',
        onPressed: _resetFields,
        colors: [Colors.grey.shade300, Colors.grey.shade500],
      ),
    ],
  );

  Widget _buildGradientButton({required String label, required VoidCallback onPressed, required List<Color> colors}) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(label, style: GoogleFonts.roboto(color: Colors.white, fontSize: 18)),
        ),
      );
}
