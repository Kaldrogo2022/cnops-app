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
      home: const MainApplicationManager(),
    );
  }
}

enum AppStep { login, otpInput, dashboard }

class MainApplicationManager extends StatefulWidget {
  const MainApplicationManager({super.key});

  @override
  State<MainApplicationManager> createState() => _MainApplicationManagerAppState();
}

class _MainApplicationManagerAppState extends State<MainApplicationManager> {
  late final WebViewController _headlessController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  AppStep _currentStep = AppStep.login;
  bool _isPageLoading = true;
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    
    _headlessController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() { _isPageLoading = false; });
            }
            
            // الفحص الديناميكي بعد انتهاء تحميل أي صفحة في الخلفية
            if (_isLoadingStatus) {
              _verifyWebsiteResponse(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.cnops.org.ma/Connexion'));
  }

  // دالة ذكية لفحص رد فعل الموقع الحقيقي ومنع الانتقال العشوائي
  void _verifyWebsiteResponse(String currentUrl) async {
    // 1. التحقق مما إذا ظهرت رسالة خطأ في صفحة الموقع (بسبب معطيات وهمية)
    String checkErrorJs = """
      (function() {
        var pageText = document.body.innerText.toLowerCase();
        // البحث عن الكلمات الدلالية للأخطاء في موقع CNOPS
        if (pageText.includes('incorrect') || pageText.includes('erreur') || pageText.includes('خطأ') || pageText.includes('فشل')) {
          return "LOGIN_FAILED";
        }
        return "NO_ERROR";
      })();
    """;

    String errorResult = await _headlessController.runJavaScriptReturningResult(checkErrorJs) as String;
    // تنظيف النتيجة من الاقتباسات الزائدة الناتجة عن الـ JSON
    errorResult = errorResult.replaceAll('"', '');

    if (errorResult == "LOGIN_FAILED") {
      setState(() {
        _isLoadingStatus = false;
      });
      _showCyberSnackBar("فشل الاتصال: معطيات الحساب غير صحيحة ❌", Colors.redAccent);
      return;
    }

    // 2. لن ننتقل لـ OTP إلا إذا تغير الرابط أو ظهر حقل الـ OTP حقيقة في الموقع
    String checkOtpFieldJs = """
      (function() {
        var otpField = document.querySelector('input[name*="code" i], input[name*="otp" i], input[id*="code" i]');
        return otpField ? "OTP_PHASE" : "STILL_WAITING";
      })();
    """;

    String otpResult = await _headlessController.runJavaScriptReturningResult(checkOtpFieldJs) as String;
    otpResult = otpResult.replaceAll('"', '');

    if (otpResult == "OTP_PHASE" || (!currentUrl.toLowerCase().contains('connexion') && currentUrl.contains('html'))) {
      setState(() {
        _isLoadingStatus = false;
        _currentStep = AppStep.otpInput; // الانتقال الآمن فقط عند التأكد
      });
      _showCyberSnackBar("تم التحقق من الحساب الحقيقي. أرسل رمز OTP 🔐", Colors.purpleAccent);
    } else {
      // إذا استغرق الموقع وقتاً طويلاً ولم تتغير الحالة، نوقف الدوران وننبه المستخدم
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isLoadingStatus) {
          setState(() { _isLoadingStatus = false; });
          _showCyberSnackBar("انتهت مهلة الطلب، قد يكون هناك نظام حماية الكابتشا يعيق السيرفر المخفي.", Colors.orangeAccent);
        }
      });
    }
  }

  void _submitLoginCredentials() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() {
      _isLoadingStatus = true;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    String jsCode = """
      (function() {
        var userField = document.querySelector('input[type="text"], input[name*="user" i], input[id*="user" i]');
        var passField = document.querySelector('input[type="password"]');
        var submitBtn = document.querySelector('button[type="submit"], input[type="submit"]');
        
        if(userField && passField) {
          userField.value = '$username';
          passField.value = '$password';
          if(submitBtn) {
            submitBtn.click();
            return "CLICKED";
          } else {
            if(document.forms.length > 0) {
              document.forms[0].submit();
              return "SUBMITTED";
            }
          }
        }
        return "NOT_FOUND";
      })();
    """;

    await _headlessController.runJavaScript(jsCode);
  }

  void _submitOtpCode() async {
    if (_otpController.text.isEmpty) return;

    setState(() {
      _isLoadingStatus = true;
    });

    String otp = _otpController.text;

    String jsCode = """
      (function() {
        var otpField = document.querySelector('input[name*="code" i], input[name*="otp" i], input[id*="code" i], input[type="text"], input[type="number"]');
        var submitBtn = document.querySelector('button[type="submit"], input[type="submit"]');
        
        if(otpField) {
          otpField.value = '$otp';
          otpField.dispatchEvent(new Event('input', { bubbles: true }));
          if(submitBtn) {
            submitBtn.click();
            return "OTP_CLICKED";
          } else {
            if(document.forms.length > 0) {
              document.forms[0].submit();
              return "OTP_SUBMITTED";
            }
          }
        }
        return "OTP_FIELD_NOT_FOUND";
      })();
    """;

    await _headlessController.runJavaScript(jsCode);
  }

  void _showCyberSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
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
          _buildCurrentUIStructure(),
        ],
      ),
    );
  }

  Widget _buildCurrentUIStructure() {
    switch (_currentStep) {
      case AppStep.login:
        return _buildLoginUi();
      case AppStep.otpInput:
        return _buildOtpUi();
      case AppStep.dashboard:
        return ProDashboard(extractedUser: _usernameController.text);
    }
  }

  Widget _buildLoginUi() {
    return Center(
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
                  const Text("CNOPS CYBER PORTAL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 30),
                  _buildTextField(_usernameController, Icons.fingerprint, "رقم التسجيل"),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, Icons.lock_open, "كلمة المرور", isPass: true),
                  const SizedBox(height: 35),
                  _buildActionButton(
                    onPressed: _isPageLoading ? null : _submitLoginCredentials,
                    text: _isPageLoading ? "جاري تهيئة النظام..." : "اتصال آمن",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpUi() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.02),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 70, color: Colors.purpleAccent),
                  const SizedBox(height: 15),
                  const Text("رمز التحقق الآمن", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("أدخل كود OTP المرسل إلى بريدك الإلكتروني", style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  _buildTextField(_otpController, Icons.security, "كود التحقق (OTP)", isCenter: true),
                  const SizedBox(height: 35),
                  _buildActionButton(
                    onPressed: _submitOtpCode,
                    text: "تأكيد ومزامنة البيانات",
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool isPass = false, bool isCenter = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
      decoration: InputDecoration(
        prefixIcon: isCenter ? null : Icon(icon, color: Colors.cyanAccent.withOpacity(0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback? onPressed, required String text, Color color = Colors.cyanAccent}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoadingStatus ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.05),
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoadingStatus 
            ? CircularProgressIndicator(color: color)
            : Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ProDashboard extends StatelessWidget {
  final String extractedUser;
  const ProDashboard({super.key, required this.extractedUser});

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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          children: const [
                            Text("قنوات البيانات النشطة", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text("تم ربط ومزامنة الحساب الأصلي بالكامل بنجاح", style: TextStyle(color: Colors.white54, fontSize: 13)),
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
              _buildNativeServiceItem("تحميل الشهادات الطبية", "روابط مدمجة جاهزة", Icons.file_download),
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
