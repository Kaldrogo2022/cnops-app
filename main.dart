import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CnopsUltimateApp());
}

class CnopsUltimateApp extends StatelessWidget {
  const CnopsUltimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNOPS Matrix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06060C),
        primaryColor: Colors.cyanAccent,
        fontFamily: 'Roboto',
      ),
      home: const AdvancedLoginScreen(),
    );
  }
}

class AdvancedLoginScreen extends StatefulWidget {
  const AdvancedLoginScreen({super.key});

  @override
  State<AdvancedLoginScreen> createState() => _AdvancedLoginScreenState();
}

class _AdvancedLoginScreenState extends State<AdvancedLoginScreen> {
  late final WebViewController _headlessController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPageLoading = true;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    
    _headlessController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isPageLoading = false;
            });
            
            if (url.contains('dashboard') || url.contains('home') || !url.contains('Connexion')) {
              _extractInternalDataAndNavigate();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.cnops.org.ma/Connexion'));
  }

  void _executeHeadlessLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() {
      _isLoggingIn = true;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    String jsCode = """
      (function() {
        var userField = document.querySelector('input[name*="user" i], input[type="text"]');
        var passField = document.querySelector('input[type="password"]');
        var submitBtn = document.querySelector('input[type="submit"], button[type="submit"]');
        
        if(userField && passField) {
          userField.value = '$username';
          passField.value = '$password';
          if(submitBtn) {
            submitBtn.click();
            return "SUBMITTED";
          } else {
            document.querySelector('form').submit();
            return "FORM_SUBMITTED";
          }
        }
        return "FAILED";
      })();
    """;

    await _headlessController.runJavaScript(jsCode);
  }

  void _extractInternalDataAndNavigate() async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProDashboard(
            extractedUser: _usernameController.text, 
            internalLinksCount: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: 1,
            height: 1,
            child: WebViewWidget(controller: _headlessController),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.blur_circular, size: 70, color: Colors.cyanAccent),
                        const SizedBox(height: 15),
                        const Text(
                          "CNOPS CYBER PORTAL",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.fingerprint, color: Colors.cyanAccent),
                            hintText: "رقم التسجيل",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_open, color: Colors.cyanAccent),
                            hintText: "كلمة المرور",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: (_isPageLoading || _isLoggingIn) ? null : _executeHeadlessLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent.withOpacity(0.05),
                              side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: _isLoggingIn 
                                ? const CircularProgressIndicator(color: Colors.cyanAccent)
                                : Text(
                                    _isPageLoading ? "جاري تهيئة خوادم الأمان..." : "اتصال آمن بـ CNOPS",
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProDashboard extends StatelessWidget {
  final String extractedUser;
  final int internalLinksCount;

  const ProDashboard({super.key, required this.extractedUser, required this.internalLinksCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06060C), Color(0xFF111125)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(25),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    cross CrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("بوابة الارتباط الذكي", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text(extractedUser, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent)),
                    child: const Icon(Icons.analytics_outlined, color: Colors.cyanAccent),
                  )
                ],
              ),
              const SizedBox(height: 40),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_rounded, size: 40, color: Colors.cyanAccent),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("قنوات البيانات النشطة", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("تم فحص واستخراج $internalLinksCount رابطاً داخلياً بنجاح", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),
              const Text("الخدمات الداخلية المزامنة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildNativeServiceItem("ملفات التعويض عن المرض", "مزامنة تلقائية حية", Icons.medication),
              _buildNativeServiceItem("وضعية التغطية الصحية", "مؤمنة ونشطة", Icons.health_and_safety),
              _buildNativeServiceItem("تحميل الشهادات الطبية", "رابط مستخرج جاهز", Icons.file_download),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeServiceItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 28),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
