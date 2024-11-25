import 'package:businessmanagemant/Subscription/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../api_services.dart';
import '../encryption.dart'; // Import your encryption helper
import 'package:http/http.dart' as http;

class EditSubscription extends StatefulWidget {
  final String subscriptionId;

  const EditSubscription({super.key, required this.subscriptionId});

  @override
  _EditSubscriptionState createState() => _EditSubscriptionState();
}

class _EditSubscriptionState extends State<EditSubscription> {
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nextRenewalDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController otherDescriptionController = TextEditingController();

  bool autoRenewal = false;
  bool isActive = true;
  bool _passwordVisible = false;

  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize encryption helper

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
    _fetchSubscriptionData();
  }

  // Fetch the subscription data to populate the fields with decryption
  Future<void> _fetchSubscriptionData() async {
    try {
      final subscriptionData = await _apiServices.fetchSubscriptionById(widget.subscriptionId);
      if (subscriptionData != null) {
        setState(() {
          serviceNameController.text = _safelyDecrypt(subscriptionData['service_name']);
          urlController.text = _safelyDecrypt(subscriptionData['url']);
          usernameController.text = _safelyDecrypt(subscriptionData['username']);
          passwordController.text = _safelyDecrypt(subscriptionData['password']);
          nextRenewalDateController.text = subscriptionData['next_renewal_date'];
          expiryDateController.text = subscriptionData['expiry_date'];
          otherDescriptionController.text = _safelyDecrypt(subscriptionData['other_description']);
          autoRenewal = subscriptionData['auto_renewal'] == '1';
          isActive = subscriptionData['active'] == '1';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subscription data: $e')),
      );
    }
  }

  String _safelyDecrypt(String? encryptedData) {
    try {
      if (encryptedData == null || encryptedData.isEmpty) return '';
      return encryptionHelper.decrypt(encryptedData);
    } catch (e) {
      print('Decryption error: $e');
      return 'Decryption failed';
    }
  }

  // Method to update the subscription with encryption
  void _updateSubscription() async {
    Provider.of<SubscriptionProvider>(context, listen: false);

    // Encrypt sensitive data before updating
    String encryptedServiceName = encryptionHelper.encrypt(serviceNameController.text);
    String encryptedUrl = encryptionHelper.encrypt(urlController.text);
    String encryptedUsername = encryptionHelper.encrypt(usernameController.text);
    String encryptedPassword = encryptionHelper.encrypt(passwordController.text);
    String encryptedOtherDescription = encryptionHelper.encrypt(otherDescriptionController.text);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://karsaazebs.com/BMS/api/v1.php?table=subscription&action=update&editid1=${widget.subscriptionId}'),
    );

    request.fields['service_name'] = encryptedServiceName;
    request.fields['url'] = encryptedUrl;
    request.fields['username'] = encryptedUsername;
    request.fields['password'] = encryptedPassword;
    request.fields['auto_renewal'] = autoRenewal ? '1' : '0';
    request.fields['next_renewal_date'] = nextRenewalDateController.text;
    request.fields['expiry_date'] = expiryDateController.text;
    request.fields['other_description'] = encryptedOtherDescription;
    request.fields['active'] = isActive ? '1' : '0';

    request.headers['Authorization'] = _apiServices.authHeader;
    request.headers['Content-Type'] = 'multipart/form-data';

    try {
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully!')),
        );
        Navigator.pop(context); // Return to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update subscription')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating subscription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Subscription",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xce9e5eb),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(serviceNameController, "Service Name", Icons.business),
                    const SizedBox(height: 20),
                    _buildTextField(urlController, "URL", Icons.link),
                    const SizedBox(height: 20),
                    _buildTextField(usernameController, "Username", Icons.person),
                    const SizedBox(height: 20),
                    _buildPasswordField("Password", passwordController),
                    const SizedBox(height: 20),
                    _buildDateField("Next Renewal Date", nextRenewalDateController),
                    const SizedBox(height: 20),
                    _buildDateField("Expiry Date", expiryDateController),
                    const SizedBox(height: 20),
                    _buildTextField(otherDescriptionController, "Other Description", Icons.description),
                    const SizedBox(height: 20),
                    _buildCheckboxRow(),
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

  // Method to build text fields
  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
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

  // Method to build password field
  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
          fillColor: Colors.white.withOpacity(0.9),
          filled: true,
          prefixIcon: const Icon(Icons.lock, color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
        style: GoogleFonts.roboto(color: Colors.black),
      ),
    );
  }

  // Method to build date field
  Widget _buildDateField(String label, TextEditingController controller) {
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
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.black),
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
      ),
    );
  }

  Widget _buildGradientButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildGradientButton(
          label: 'Update',
          onPressed: _updateSubscription,
          colors: [Colors.lightBlueAccent, Colors.blueAccent],
        ),
        _buildGradientButton(
          label: 'Back to List',
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

  Widget _buildCheckboxRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "Auto Renewal",
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
            ),
            Checkbox(
              value: autoRenewal,
              onChanged: (bool? value) {
                setState(() {
                  autoRenewal = value ?? false;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text(
              "Active",
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
            ),
            Checkbox(
              value: isActive,
              onChanged: (bool? value) {
                setState(() {
                  isActive = value ?? true;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
