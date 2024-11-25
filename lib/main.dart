import 'package:businessmanagemant/Credentials/add_new_credential1.dart';
import 'package:businessmanagemant/Provider_statemanagement/subscription_payment_provider.dart';
import 'package:businessmanagemant/Subscription/add_new_subscription.dart';
import 'package:businessmanagemant/bank/add_new_bank_details.dart';
import 'package:businessmanagemant/dashboard_screen.dart';
import 'package:businessmanagemant/login_page.dart';
import 'package:businessmanagemant/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Credentials/Credentials_provider.dart';
import 'Provider_statemanagement/Login_provider.dart';
import 'Provider_statemanagement/bank_details_provider.dart';
import 'Provider_statemanagement/dashboard_provider.dart';
import 'Subscription/subscription_provider.dart';
import 'api_services.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => BankDetailsProvider()),
        ChangeNotifierProvider(create: (_) => CredentialsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<SubscriptionPaymentProvider>(
          create: (context) => SubscriptionPaymentProvider(apiServices: context.read<ApiServices>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, _) {
        return MaterialApp(
          title: 'Business Management App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: loginProvider.isLoggedIn ? '/dashboard' : '/',
          routes: {
            '/': (context) => const LoginPage(title: 'D'),
            '/login_page': (context) => const LoginPage(title: '',),

            // Replace 'UserName' with the actual username if needed
            '/dashboard': (context) {
              final username = Provider.of<LoginProvider>(context,listen: false).userName;
              final userId = Provider.of<LoginProvider>(context, listen: false).userId;
              if (userId == null){
                return const LoginPage(title: '',);
              }
              return DashboardScreen(userId: userId, username: username.toString(), title: '',);
            },

            '/add_credential': (context) {
              final userId = Provider.of<LoginProvider>(context, listen: false).userId;
              if (userId == null){
                return const LoginPage(title: '',);
              }
              return AddCredential(userId: userId);
            },

            '/add_new_subscription': (context) {
              final userId = Provider.of<LoginProvider>(context, listen: false).userId;
              if (userId == null) {
                print('Error: userId is null, redirecting to LoginPage');
                // Handle the case where userId is null (e.g., by redirecting to the login page)
                return const LoginPage(title: '',);
              }
              return AddSubscription(userId: userId); // Pass userId to AddSubscription
            },

            '/add_bank_details': (context) {
              final userId = Provider.of<LoginProvider>(context, listen: false).userId;

              if (userId == null) {
                // If userId is null, navigate to the LoginPage
                return const LoginPage(title: '',);
              }
              // If userId is not null, navigate to AddBankDetails with the userId
              return AddBankDetails(userId: userId);
            },


          },
        );
      },
    );
  }
}
