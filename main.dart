// استبدل هذا الجزء بالكامل داخل ملف main.dart

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
  bool _needsManualInteraction = false; // نظام الطوارئ: إظهار المتصفح عند الكابتشا

  @override
  void initState() {
    super.initState();
    
    _headlessController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF06060C))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() { _isPageLoading = false; });
            }
            
            // مراقبة ذكية للرابط: إذا تغير الرابط ولم يعد يحتوي على كلمة Connexion أو Login
            if (!url.toLowerCase().contains('connexion') && !url.toLowerCase().contains('login')) {
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
      _needsManualInteraction = false; // إبقاء المتصفح مخفياً في البداية
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    // سكربت حقن مرن يبحث عن أي حقل إدخال نشط
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
            document.forms[0].submit();
            return "SUBMITTED";
          }
        }
        return "NOT_FOUND";
      })();
    """;

    await _headlessController.runJavaScript(jsCode);

    // نظام الطوارئ والتكيف: إذا لم يتغير الرابط بعد 6 ثوانٍ، فهناك كابتشا أو خطأ
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoggingIn) {
        setState(() {
          _isLoggingIn = false; // إيقاف الدوران
          _needsManualInteraction = true; // إظهار شاشة CNOPS الحقيقية ليتصرف المستخدم
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نظام الحماية (Captcha) أو خطأ في البيانات يمنع الدخول التلقائي. يرجى المتابعة يدوياً.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          )
        );
      }
    });
  }

  void _extractInternalDataAndNavigate() async {
    // الانتقال التلقائي للوحة التحكم الاحترافية
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProDashboard(
            extractedUser: _usernameController.text.isNotEmpty ? _usernameController.text : "مستخدم CNOPS", 
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
          // 1. المتصفح الحقيقي (يظهر فقط في حالة الطوارئ كالكابتشا)
          Visibility(
            visible: _needsManualInteraction,
            maintainState: true,
            child: SafeArea(child: WebViewWidget(controller: _headlessController)),
          ),

          // 2. الواجهة المستقبلية الاحترافية (تختفي إذا ظهر المتصفح)
          if (!_needsManualInteraction)
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
