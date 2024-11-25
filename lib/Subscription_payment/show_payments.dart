import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import '../encryption.dart'; // Import your encryption helper
import 'edit_subscription_payment.dart'; // Import the edit screen

class ShowPaymentsPage extends StatefulWidget {
  final String subscriptionId;

  const ShowPaymentsPage({Key? key, required this.subscriptionId}) : super(key: key);

  @override
  _ShowPaymentsPageState createState() => _ShowPaymentsPageState();
}

class _ShowPaymentsPageState extends State<ShowPaymentsPage> {
  List<Map<String, dynamic>> paymentData = [];
  Map<String, String> currencyMap = {}; // To store currency ID to name mapping
  Map<String, String> paymentMethodMap = {}; // To store payment method ID to name mapping
  bool isLoading = true;

  final ApiServices apiServices = ApiServices(); // Initialize the ApiServices
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize encryption helper

  @override
  void initState() {
    super.initState();
    _loadDropdownData(); // Load currency and payment method names
    _fetchPaymentDetails();
  }

  Future<void> _loadDropdownData() async {
    try {
      // Fetch Currencies
      final Map<String, dynamic>? currenciesData = await apiServices.fetchCurrencies();
      if (currenciesData != null && currenciesData['data'] != null) {
        setState(() {
          currencyMap = Map.fromIterable(
            currenciesData['data'],
            key: (item) => item['id'].toString(),
            value: (item) => item['name'].toString(),
          );
        });
      }

      // Fetch Payment Methods
      final Map<String, dynamic>? paymentMethodsData = await apiServices.fetchPaymentMethods();
      if (paymentMethodsData != null && paymentMethodsData['data'] != null) {
        setState(() {
          paymentMethodMap = Map.fromIterable(
            paymentMethodsData['data'],
            key: (item) => item['id'].toString(),
            value: (item) => item['name'].toString(),
          );
        });
      }
    } catch (e) {
      print('Error loading dropdown data: $e');
      _showErrorDialog('Failed to load currencies or payment methods.');
    }
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final Map<String, dynamic>? fetchedData =
      await apiServices.fetchSubscriptionPayments(int.parse(widget.subscriptionId));

      if (fetchedData != null && fetchedData['data'] != null) {
        setState(() {
          paymentData = List<Map<String, dynamic>>.from(
            fetchedData['data'].map((payment) {
              // Decrypt necessary fields
              payment['subscription_cost'] = _safelyDecrypt(payment['subscription_cost']);
              payment['remarks'] = _safelyDecrypt(payment['remarks']);

              // Decode Base64 to image bytes for display
              if (payment['important_attachments'] != null &&
                  payment['important_attachments'].isNotEmpty) {
                try {
                  payment['file_image'] = Image.memory(
                    base64Decode(payment['important_attachments']),
                    fit: BoxFit.contain,
                  );
                } catch (e) {
                  print('Error decoding Base64 image: $e');
                  payment['file_image'] = const Text("Invalid Image");
                }
              } else {
                payment['file_image'] = const Text("No Image Available");
              }
              return payment;
            }),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to load payment details.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching payment details: $e');
    }
  }

  String _safelyDecrypt(String? encryptedData) {
    try {
      if (encryptedData == null || encryptedData.isEmpty) return 'N/A';
      return encryptionHelper.decrypt(encryptedData);
    } catch (e) {
      print('Decryption error: $e');
      return 'Decryption failed';
    }
  }

  Future<void> _refreshPayments() async {
    setState(() {
      isLoading = true;
    });
    await _fetchPaymentDetails();
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

  Future<void> _deleteSubscriptionPayments(int index) async {
    String id = paymentData[index]['id'].toString();
    bool success = await apiServices.deleteSubscriptionPayments(id);
    if (success) {
      setState(() {
        paymentData.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment deleted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete payment')),
      );
    }
  }

  void _onDeletePayment(int index) async {
    bool deleteConfirmed = await _showDeleteConfirmationDialog();
    if (deleteConfirmed) {
      await _deleteSubscriptionPayments(index);
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this payment?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }

  void _onEditPayment(int index) {
    String paymentId = paymentData[index]['id'].toString();

    // Navigate to the EditSubscriptionPayment page and pass the paymentId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubscriptionPayment(paymentId: paymentId),
      ),
    ).then((value) {
      // After coming back, refresh the payments list
      _refreshPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payment Details",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        backgroundColor: const Color(0xce9e5eb),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              Colors.transparent,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refreshPayments,
          child: paymentData.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: paymentData.length,
              itemBuilder: (context, index) {
                final payment = paymentData[index];
                return _buildPaymentCard(payment, index);
              },
            ),
          )
              : const Center(
            child: Text(
              'No payment details available',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index) {
    return Card(
      color: Colors.white,
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Start Date:', payment['start_date']),
            const SizedBox(height: 10),
            _buildDetailRow('End Date:', payment['end_date']),
            const SizedBox(height: 10),
            _buildDetailRow('Cost:', payment['subscription_cost']),
            const SizedBox(height: 10),
            _buildDetailRow('Currency:', currencyMap[payment['currency_id']] ?? 'Unknown'),
            const SizedBox(height: 10),
            _buildDetailRow('Payment Method:', paymentMethodMap[payment['payment_method_id']] ?? 'Unknown'),
            const SizedBox(height: 10),
            _buildDetailRow('Remarks:', payment['remarks'] ?? 'N/A'),
            const SizedBox(height: 10),
            const Text('Attachment:'),
            payment['file_image'], // Display the decoded image or message
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGradientButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  onPressed: () => _onDeletePayment(index),
                  colors: [Colors.redAccent, Colors.red],
                  textColor: Colors.white,
                ),
                _buildGradientButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  onPressed: () => _onEditPayment(index),
                  colors: [Colors.blueAccent, Colors.blue],
                  textColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.robotoCondensed(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.roboto(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
