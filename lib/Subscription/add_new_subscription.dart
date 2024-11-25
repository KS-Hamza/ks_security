import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import '../encryption.dart';
import 'package:http/http.dart' as http;

class AddSubscription extends StatefulWidget {
  final int userId; // Add userId parameter

  const AddSubscription({super.key, required this.userId}); // Add required keyword for userId

  @override
  _AddSubscriptionState createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends State<AddSubscription> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
  bool _usernameVisible = false;

  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper();

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
    _usernameVisible = false;
  }

  // Method to handle saving the subscription with encryption and userId
  void _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      // Encrypt sensitive data
      String encryptedServiceName = encryptionHelper.encrypt(serviceNameController.text);
      String encryptedUsername = encryptionHelper.encrypt(usernameController.text);
      String encryptedPassword = encryptionHelper.encrypt(passwordController.text);
      String encryptedUrl = urlController.text.isNotEmpty ? encryptionHelper.encrypt(urlController.text) : '';
      String encryptedOtherDescription = otherDescriptionController.text.isNotEmpty
          ? encryptionHelper.encrypt(otherDescriptionController.text)
          : '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://karsaazebs.com/BMS/api/v1.php?table=subscription&action=insert'),
      );

      // Adding encrypted fields and userId (converted to String) to the request
      request.fields['user_id'] = widget.userId.toString(); // Convert userId to String
      request.fields['service_name'] = encryptedServiceName;
      request.fields['url'] = encryptedUrl;
      request.fields['username'] = encryptedUsername;
      request.fields['password'] = encryptedPassword;
      request.fields['auto_renewal'] = autoRenewal ? '1' : '0';
      request.fields['next_renewal_date'] = nextRenewalDateController.text;
      request.fields['expiry_date'] = expiryDateController.text;
      request.fields['other_description'] = encryptedOtherDescription;
      request.fields['active'] = isActive ? '1' : '0';

      // Adding the authorization header
      request.headers['Authorization'] = _apiServices.authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      try {
        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription added successfully!')),
          );
          Navigator.pop(context); // Return to the previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add subscription')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subscription: $e')),
        );
      }
    }
  }


  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: "Enter $label",
            hintStyle: GoogleFonts.roboto(color: Colors.black),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUsernameField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !_usernameVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person),
            hintText: "Enter $label",
            hintStyle: GoogleFonts.roboto(color: Colors.black),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(_usernameVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _usernameVisible = !_usernameVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock),
            hintText: "Enter $label",
            hintStyle: GoogleFonts.roboto(color: Colors.black),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today),
            hintText: "Select $label",
            hintStyle: GoogleFonts.roboto(color: Colors.black),
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
        ),
      ],
    );
  }

  Widget _buildCheckboxRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text("Auto Renewal", style: GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
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
            Text("Active", style: GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Subscription", style: GoogleFonts.roboto(fontSize: 25, color: Colors.black)),
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
                      _buildInputField("Service Name", serviceNameController, Icons.text_fields),
                      const SizedBox(height: 20),
                      _buildInputField("URL", urlController, Icons.link, isOptional: true),
                      const SizedBox(height: 20),
                      _buildUsernameField("Username", usernameController),
                      const SizedBox(height: 20),
                      _buildPasswordField("Password", passwordController),
                      const SizedBox(height: 20),
                      _buildDateField("Next Renewal Date", nextRenewalDateController),
                      const SizedBox(height: 20),
                      _buildDateField("Expiry Date", expiryDateController),
                      const SizedBox(height: 20),
                      _buildInputField("Other Description", otherDescriptionController, Icons.description, isOptional: true),
                      const SizedBox(height: 20),
                      _buildCheckboxRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed: _saveSubscription,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Save", style: GoogleFonts.roboto(color: Colors.white, fontSize: 18)),
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
}
