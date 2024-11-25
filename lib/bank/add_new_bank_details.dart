import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import 'package:http/http.dart' as http;
import '../encryption.dart';


class AddBankDetails extends StatefulWidget {
  final int userId;

  const AddBankDetails({super.key, required this.userId});


  @override
  _AddBankDetailsState createState() => _AddBankDetailsState();
}

class _AddBankDetailsState extends State<AddBankDetails> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardCreationDateController = TextEditingController();
  final TextEditingController cardExpiryDateController = TextEditingController(); // Expiry Date Controller
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchCodeController = TextEditingController();
  final TextEditingController accountHolderNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();

  final ApiServices _apiServices = ApiServices();

  String? accountTypeId;
  String? currencyId;
  String? accountStatusId;

  List<Map<String, String>> accountTypeList = [];
  List<Map<String, String>> currencyList = [];
  List<Map<String, String>> accountStatusList = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final accountTypesResponse = await _apiServices.fetchAccountTypeList();
    if (accountTypesResponse != null && accountTypesResponse['data'] != null) {
      setState(() {
        accountTypeList = (accountTypesResponse['data'] as List)
            .map((item) => {'id': item['id'].toString(), 'name': item['name'].toString()})
            .toList();
      });
    }

    final currencyResponse = await _apiServices.fetchCurrenciesList();
    if (currencyResponse != null && currencyResponse['data'] != null) {
      setState(() {
        currencyList = (currencyResponse['data'] as List)
            .map((item) => {'id': item['id'].toString(), 'name': item['name'].toString()})
            .toList();
      });
    }

    final accountStatusResponse = await _apiServices.fetchAccountStatusList();
    if (accountStatusResponse != null && accountStatusResponse['data'] != null) {
      setState(() {
        accountStatusList = (accountStatusResponse['data'] as List)
            .map((item) => {'id': item['id'].toString(), 'name': item['name'].toString()})
            .toList();
      });
    }
  }
  void _saveBankDetails() async {
    final encryptionHelper = AESEncryptionHelper();

    if (_formKey.currentState!.validate()) {
      try {
        // Encrypt sensitive data before sending it to the server
        final encryptedAccountNumber = encryptionHelper.encrypt(accountNumberController.text);
        final encryptedBalance = encryptionHelper.encrypt(balanceController.text);
        final encryptedCVV = encryptionHelper.encrypt(cvvController.text);
        final encryptedCardNumber = encryptionHelper.encrypt(cardNumberController.text);
        final encryptedBankName = encryptionHelper.encrypt(bankNameController.text);
        final encryptedBranchName = encryptionHelper.encrypt(branchNameController.text);
        final encryptedBranchCode = encryptionHelper.encrypt(branchCodeController.text);
        final encryptedAccountHolderName = encryptionHelper.encrypt(accountHolderNameController.text);
        final encryptedPhoneNumber = encryptionHelper.encrypt(phoneNumberController.text);
        final encryptedEmailAddress = encryptionHelper.encrypt(emailAddressController.text);

        // Print encrypted values for debugging
        print('Encrypted Account Number: $encryptedAccountNumber');
        print('Encrypted Balance: $encryptedBalance');
        print('Encrypted CVV: $encryptedCVV');
        print('Encrypted Card Number: $encryptedCardNumber');
        print('Encrypted Bank Name: $encryptedBankName');
        print('Encrypted Branch Name: $encryptedBranchName');
        print('Encrypted Branch Code: $encryptedBranchCode');
        print('Encrypted Account Holder Name: $encryptedAccountHolderName');
        print('Encrypted Phone Number: $encryptedPhoneNumber');
        print('Encrypted Email Address: $encryptedEmailAddress');

        // Create the HTTP POST request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://karsaazebs.com/BMS/api/v1.php?table=bank_details&action=insert'),
        );

        // Add encrypted data as fields
        request.fields['account_number'] = encryptedAccountNumber;
        request.fields['balance'] = encryptedBalance;
        request.fields['cvv'] = encryptedCVV;
        request.fields['card_number'] = encryptedCardNumber;
        request.fields['bank_name'] = encryptedBankName;
        request.fields['branch_name'] = encryptedBranchName;
        request.fields['branch_code'] = encryptedBranchCode;
        request.fields['account_holder_name'] = encryptedAccountHolderName;
        request.fields['phone_number'] = encryptedPhoneNumber;
        request.fields['email_address'] = encryptedEmailAddress;

        // Add plain data fields
        request.fields['card_creation_date'] = cardCreationDateController.text;
        request.fields['card_expiry-date'] = cardExpiryDateController.text;
        request.fields['account_type_id'] = accountTypeId ?? '';
        request.fields['currency_id'] = currencyId ?? '';
        request.fields['account_status_id'] = accountStatusId ?? '';

        // Add user_id to the request
        request.fields['user_id'] = widget.userId.toString();

        // Add authorization header
        request.headers['Authorization'] = _apiServices.authHeader;
        request.headers['Content-Type'] = 'multipart/form-data';

        // Send request and handle response
        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank details added successfully!')),
          );
          Navigator.pop(context);
        } else {
          // Read response data for debugging
          final responseBody = await response.stream.bytesToString();
          print('Failed response: $responseBody'); // Log error details

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add bank details: $responseBody')),
          );
        }
      } catch (e) {
        print('Error adding bank details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bank details: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add New Bank Details",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  Column(
                    children: [
                      _buildInputField("Account Number", accountNumberController, Icons.account_balance_wallet),
                      _buildDropdownField("Account Type", accountTypeId, accountTypeList, Icons.category, (value) {
                        setState(() {
                          accountTypeId = value;
                        });
                      }),
                      _buildInputField("Bank Name", bankNameController, Icons.account_balance),
                      _buildInputField("Branch Name", branchNameController, Icons.location_city),
                      _buildInputField("Branch Code", branchCodeController, Icons.code),
                      _buildInputField("Account Holder Name", accountHolderNameController, Icons.person),
                      _buildDropdownField("Currency", currencyId, currencyList, Icons.money, (value) {
                        setState(() {
                          currencyId = value;
                        });
                      }),
                      _buildDropdownField("Account Status", accountStatusId, accountStatusList, Icons.check_circle, (value) {
                        setState(() {
                          accountStatusId = value;
                        });
                      }),
                      _buildInputField("Balance", balanceController, Icons.account_balance_wallet),
                      _buildInputField("CVV", cvvController, Icons.lock),
                      _buildInputField("Card Number", cardNumberController, Icons.credit_card),
                      _buildDateField("Card Creation Date", cardCreationDateController),
                      _buildDateField("Card Expiry Date", cardExpiryDateController),
                      _buildInputField("Phone Number", phoneNumberController, Icons.phone),
                      _buildInputField("Email Address", emailAddressController, Icons.email),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveBankDetails,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.black),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedId, List<Map<String, String>> items, IconData icon, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.black),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        value: selectedId,
        items: items.map((Map<String, String> item) {
          return DropdownMenuItem<String>(
            value: item['id'],
            child: Text(item['name'] ?? ''),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.black),
          prefixIcon: Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            setState(() {
              controller.text = "${pickedDate.toLocal()}".split(' ')[0];
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }
}
