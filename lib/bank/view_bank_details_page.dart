import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import '../encryption.dart';
import 'edit_bank_details.dart';
import 'package:flutter/services.dart';

class ViewBankDetailsPage extends StatefulWidget {
  final String bankId;

  const ViewBankDetailsPage({Key? key, required this.bankId}) : super(key: key);

  @override
  _ViewBankDetailsPageState createState() => _ViewBankDetailsPageState();
}

class _ViewBankDetailsPageState extends State<ViewBankDetailsPage> {
  Map<String, dynamic>? bankData;
  bool isLoading = true;
  bool isCvvVisible = false;
  bool isCardNumberVisible = false;
  bool isBalanceVisible = false;
  final ApiServices apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize the encryption helper

  // Mapping dictionaries to store lookup values
  Map<String, String> accountTypeMap = {};
  Map<String, String> currencyMap = {};
  Map<String, String> accountStatusMap = {};

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  // Safe decryption method
  String safeDecrypt(String encryptedText) {
    try {
      return encryptionHelper.decrypt(encryptedText);
    } catch (e) {
      print('Decryption failed for: $encryptedText with error: $e');
      return encryptedText; // Return the original text if decryption fails
    }
  }

  Future<void> _fetchBankDetails() async {
    try {
      // Fetch bank details
      final Map<String, dynamic>? fetchedData = await apiServices.fetchBankDetailById(widget.bankId);

      // Fetch lookup data for account types, currencies, and account statuses
      final accountTypesResponse = await apiServices.fetchAccountTypeList();
      final currencyResponse = await apiServices.fetchCurrenciesList();
      final accountStatusResponse = await apiServices.fetchAccountStatusList();

      setState(() {
        // Map IDs to names for account types
        if (accountTypesResponse != null && accountTypesResponse['data'] != null) {
          accountTypeMap = Map.fromIterable(
            accountTypesResponse['data'],
            key: (item) => item['id'].toString(),
            value: (item) => item['name'].toString(),
          );
        }

        // Map IDs to names for currencies
        if (currencyResponse != null && currencyResponse['data'] != null) {
          currencyMap = Map.fromIterable(
            currencyResponse['data'],
            key: (item) => item['id'].toString(),
            value: (item) => item['name'].toString(),
          );
        }

        // Map IDs to names for account statuses
        if (accountStatusResponse != null && accountStatusResponse['data'] != null) {
          accountStatusMap = Map.fromIterable(
            accountStatusResponse['data'],
            key: (item) => item['id'].toString(),
            value: (item) => item['name'].toString(),
          );
        }

        // Decrypt only the fields that are encrypted
        if (fetchedData != null && fetchedData['data'] != null) {
          bankData = {
            'id': fetchedData['data']['id'],
            'account_number': safeDecrypt(fetchedData['data']['account_number']),
            'account_type_id': fetchedData['data']['account_type_id'], // No decryption needed
            'bank_name': safeDecrypt(fetchedData['data']['bank_name']),
            'branch_name': safeDecrypt(fetchedData['data']['branch_name']),
            'branch_code': safeDecrypt(fetchedData['data']['branch_code']),
            'account_holder_name': safeDecrypt(fetchedData['data']['account_holder_name']),
            'currency_id': fetchedData['data']['currency_id'], // No decryption needed
            'balance': safeDecrypt(fetchedData['data']['balance']),
            'cvv': safeDecrypt(fetchedData['data']['cvv']),
            'card_number': safeDecrypt(fetchedData['data']['card_number']),
            'card_creation_date': fetchedData['data']['card_creation_date'], // No decryption needed
            'card_expiry-date': fetchedData['data']['card_expiry-date'], // No decryption needed
            'phone_number': safeDecrypt(fetchedData['data']['phone_number']),
            'email_address': safeDecrypt(fetchedData['data']['email_address']),
            'account_status_id': fetchedData['data']['account_status_id'], // No decryption needed
          };
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching bank details: $e');
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

  void _onEditBankDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBankDetailsPage(bankId: widget.bankId),
      ),
    );
  }

  Future<void> _deleteBankDetails() async {
    bool deleteConfirmed = await _showDeleteConfirmationDialog();
    if (deleteConfirmed) {
      bool success = await apiServices.deleteBank(widget.bankId);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details deleted successfully!')),
        );
      } else {
        _showErrorDialog('Failed to delete bank details.');
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete these bank details?'),
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bank Details",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xce9e5eb),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bankData == null
          ? const Center(child: Text('No details available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailField('Account Number', bankData!['account_number']),
                    _buildDetailField('Account Type', accountTypeMap[bankData!['account_type_id']] ?? 'Not provided'),
                    _buildDetailField('Bank Name', bankData!['bank_name']),
                    _buildDetailField('Branch Name', bankData!['branch_name']),
                    _buildDetailField('Branch Code', bankData!['branch_code']),
                    _buildDetailField('Account Holder Name', bankData!['account_holder_name']),
                    _buildDetailField('Currency', currencyMap[bankData!['currency_id']] ?? 'Not provided'),
                    _buildSensitiveDetailField('Balance', bankData!['balance'], isVisible: isBalanceVisible, toggleVisibility: () {
                      setState(() {
                        isBalanceVisible = !isBalanceVisible;
                      });
                    }),
                    _buildSensitiveDetailField('CVV', bankData!['cvv'], isVisible: isCvvVisible, toggleVisibility: () {
                      setState(() {
                        isCvvVisible = !isCvvVisible;
                      });
                    }),
                    _buildSensitiveDetailField('Card Number', bankData!['card_number'], isVisible: isCardNumberVisible, toggleVisibility: () {
                      setState(() {
                        isCardNumberVisible = !isCardNumberVisible;
                      });
                    }),
                    _buildDetailField('Card Creation Date', bankData!['card_creation_date']),
                    _buildDetailField('Card Expiry Date', bankData!['card_expiry-date']),
                    _buildDetailField('Phone Number', bankData!['phone_number']),
                    _buildDetailField('Email Address', bankData!['email_address']),
                    _buildDetailField('Account Status', accountStatusMap[bankData!['account_status_id']] ?? 'Not provided'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGradientButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  onPressed: _deleteBankDetails,
                  colors: [Colors.redAccent, Colors.pinkAccent],
                ),
                _buildGradientButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  onPressed: _onEditBankDetails,
                  colors: [Colors.blue, Colors.purple],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  value != null ? value.toString() : 'Not provided',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
                },
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSensitiveDetailField(String label, dynamic value, {required bool isVisible, required VoidCallback toggleVisibility}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  isVisible ? (value ?? 'Not provided') : '●●●●●',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
                ),
              ),
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: toggleVisibility,
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
                },
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
