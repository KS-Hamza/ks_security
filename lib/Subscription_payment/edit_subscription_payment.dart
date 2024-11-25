import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../api_services.dart';

class EditSubscriptionPayment extends StatefulWidget {
  final String paymentId;

  const EditSubscriptionPayment({Key? key, required this.paymentId}) : super(key: key);

  @override
  _EditSubscriptionPaymentState createState() => _EditSubscriptionPaymentState();
}

class _EditSubscriptionPaymentState extends State<EditSubscriptionPayment> {
  final TextEditingController subscriptionIdController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController subscriptionCostController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  String? selectedCurrencyId;
  String? selectedPaymentMethodId;
  String? selectedFile;
  bool isLoading = true;

  List<Map<String, String>> currencyOptions = [];
  List<Map<String, String>> paymentMethodOptions = [];

  final ApiServices apiServices = ApiServices();

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
    _loadDropdownData();
  }

  Future<void> _fetchPaymentData() async {
    try {
      final paymentData = await apiServices.fetchSubscriptionPaymentById(widget.paymentId);
      if (paymentData != null) {
        setState(() {
          subscriptionIdController.text = paymentData['subscription_id'].toString();
          startDateController.text = paymentData['start_date'];
          endDateController.text = paymentData['end_date'];
          subscriptionCostController.text = paymentData['subscription_cost'].toString();
          remarksController.text = paymentData['remarks'] ?? '';
          selectedCurrencyId = paymentData['currency_id'];
          selectedPaymentMethodId = paymentData['payment_method_id'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching payment data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
            }),
          );
        });
      }

      final Map<String, dynamic>? paymentMethodsData = await apiServices.fetchPaymentMethods();
      if (paymentMethodsData != null && paymentMethodsData['data'] != null) {
        setState(() {
          paymentMethodOptions = List<Map<String, String>>.from(
            paymentMethodsData['data'].map((method) => {
              'id': method['id'].toString(),
              'name': method['name'].toString(),
            }),
          );
        });
      }
    } catch (e) {
      print('Error loading dropdown data: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Subscription Payment",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xce9e5eb),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Subscription Id"),
                    _buildTextField(subscriptionIdController, "Subscription Id", Icons.confirmation_number, readOnly: true),
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
                    _buildLabel("Important Attachments"),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon,
      {bool readOnly = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
          fillColor: Colors.white.withOpacity(0.9),
          filled: true,
          prefixIcon: Icon(icon, color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        style: GoogleFonts.roboto(color: Colors.black),
      ),
    );
  }

  Widget _buildDropdownField(List<Map<String, String>> options, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: options.any((option) => option['id'] == selectedValue) ? selectedValue : null,
        decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(0.9),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        items: options.map((Map<String, String> option) {
          return DropdownMenuItem<String>(
            value: option['id'],
            child: Text(option['name']!, style: GoogleFonts.roboto(color: Colors.black)),
          );
        }).toList(),
        onChanged: onChanged,
        style: GoogleFonts.roboto(color: Colors.black),
      ),
    );
  }


  Widget _buildDateField(String label, TextEditingController controller, IconData icon) {
    return Padding(
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
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
  }

  Widget _buildFilePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedFile ?? 'No file chosen',
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement file picker functionality here
              String? filePath = 'dummy/path/to/file.pdf'; // Example file path
              setState(() {
                selectedFile = filePath;
              });
            },
            child: Text('Choose File', style: GoogleFonts.roboto(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildGradientButton(
          label: 'Update',
          onPressed: _updatePayment,
          colors: [Colors.lightBlueAccent, Colors.blueAccent],
        ),
        _buildGradientButton(
          label: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          colors: [Colors.grey.shade300, Colors.grey.shade500],
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _updatePayment() async {
    Map<String, String> formData = {
      'subscription_id': subscriptionIdController.text,
      'start_date': startDateController.text,
      'end_date': endDateController.text,
      'subscription_cost': subscriptionCostController.text,
      'currency_id': selectedCurrencyId ?? '',
      'payment_method_id': selectedPaymentMethodId ?? '',
      'remarks': remarksController.text,
    };

    File? attachmentFile = selectedFile != null ? File(selectedFile!) : null;
    bool success = await apiServices.updateSubscriptionPayments(widget.paymentId, formData, attachmentFile);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription payment updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update subscription payment')),
      );
    }
  }
}
