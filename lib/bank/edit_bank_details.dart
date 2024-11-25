import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import '../encryption.dart';

class EditBankDetailsPage extends StatefulWidget {
  final String bankId;

  const EditBankDetailsPage({Key? key, required this.bankId}) : super(key: key);

  @override
  _EditBankDetailsPageState createState() => _EditBankDetailsPageState();
}

class _EditBankDetailsPageState extends State<EditBankDetailsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardCreationDateController = TextEditingController();
  final TextEditingController cardExpiryDateController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchCodeController = TextEditingController();
  final TextEditingController accountHolderNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();

  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize encryption helper

  String? accountTypeId;
  String? currencyId;
  String? accountStatusId;

  List<Map<String, String>> accountTypeList = [];
  List<Map<String, String>> currencyList = [];
  List<Map<String, String>> accountStatusList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
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

  Future<void> _fetchBankDetails() async {
    print("Fetching bank details...");
    final fetchedData = await _apiServices.fetchBankDetailById(widget.bankId);
    print("Fetched data: $fetchedData");
    if (fetchedData != null && fetchedData['data'] != null) {
      setState(() {
        accountNumberController.text = encryptionHelper.decrypt(fetchedData['data']['account_number']) ?? '';
        balanceController.text = encryptionHelper.decrypt(fetchedData['data']['balance']) ?? '';
        cvvController.text = encryptionHelper.decrypt(fetchedData['data']['cvv']) ?? '';
        cardNumberController.text = encryptionHelper.decrypt(fetchedData['data']['card_number']) ?? '';
        cardCreationDateController.text = fetchedData['data']['card_creation_date'] ?? '';
        cardExpiryDateController.text = fetchedData['data']['card_expiry-date'] ?? '';
        bankNameController.text = encryptionHelper.decrypt(fetchedData['data']['bank_name']) ?? '';
        branchNameController.text = encryptionHelper.decrypt(fetchedData['data']['branch_name']) ?? '';
        branchCodeController.text = encryptionHelper.decrypt(fetchedData['data']['branch_code']) ?? '';
        accountHolderNameController.text = encryptionHelper.decrypt(fetchedData['data']['account_holder_name']) ?? '';
        phoneNumberController.text = encryptionHelper.decrypt(fetchedData['data']['phone_number']) ?? '';
        emailAddressController.text = encryptionHelper.decrypt(fetchedData['data']['email_address']) ?? '';
        accountTypeId = fetchedData['data']['account_type_id']?.toString();
        currencyId = fetchedData['data']['currency_id']?.toString();
        accountStatusId = fetchedData['data']['account_status_id']?.toString();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load bank details.')),
      );
    }
  }


  void _updateBankDetails() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'account_number': encryptionHelper.encrypt(accountNumberController.text),
        'balance': encryptionHelper.encrypt(balanceController.text),
        'cvv': encryptionHelper.encrypt(cvvController.text),
        'card_number': encryptionHelper.encrypt(cardNumberController.text),
        'card_creation_date': cardCreationDateController.text,
        'card_expiry-date': cardExpiryDateController.text,
        'bank_name': encryptionHelper.encrypt(bankNameController.text),
        'branch_name': encryptionHelper.encrypt(branchNameController.text),
        'branch_code': encryptionHelper.encrypt(branchCodeController.text),
        'account_holder_name': encryptionHelper.encrypt(accountHolderNameController.text),
        'phone_number': encryptionHelper.encrypt(phoneNumberController.text),
        'email_address': encryptionHelper.encrypt(emailAddressController.text),
        'account_type_id': accountTypeId ?? '',
        'currency_id': currencyId ?? '',
        'account_status_id': accountStatusId ?? '',
      };

      bool success = await _apiServices.updateBankDetail(widget.bankId, updatedData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bank details.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Bank Details",
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                    onPressed: _updateBankDetails,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Update",
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
