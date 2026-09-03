// ==========================================
// VOIDGRAM FLUTTER MOBILE APP
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- БЛОК 6/10: ТОЧКА ВХОДУ ТА ТЕМА ДОДАТКУ ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "pk_test_mock_key"; // Публічний ключ Stripe
  runApp(const VoidgramApp());
}

class VoidgramApp extends StatelessWidget {
  const VoidgramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voidgram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        primaryColor: const Color(0xFF2196F3),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF161925)),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- БЛОК 7/10: ГОЛОВНИЙ ЕКРАН ТА СТРІЧКА ПОСТІВ ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voidgram', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoCallScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () => SubscriptionService.buySubscription(context, 'price_personal_1_5'),
          )
        ],
      ),
      body: ListView(
        children: [
          // Блок Stories
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueAccent,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 10}'),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white10),
          
          // Пости
          const PostCard(
            username: "official_store",
            isVerified: true,
            isBusiness: true,
            postText: "Нові надходження у нашому каталозі! Переглядайте вітрину товарів у профілі.",
            likes: 412,
          ),
          const PostCard(
            username: "alex_dev",
            isVerified: true,
            isBusiness: false,
            postText: "Без алгоритмів, без ШІ-сміття. Тільки чистий хронологічний фід у Voidgram! 🚀",
            likes: 89,
          ),
        ],
      ),
    );
  }
}

// --- БЛОК 8/10: КАРТКА ПОСТА З ВЕРИФІКАЦІЄЮ ТА ПОДАРУНКАМИ ---
class PostCard extends StatelessWidget {
  final String username;
  final bool isVerified;
  final bool isBusiness;
  final String postText;
  final int likes;

  const PostCard({
    super.key,
    required this.username,
    required this.isVerified,
    required this.isBusiness,
    required this.postText,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161925),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$username')),
                const SizedBox(width: 10),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified, 
                    color: isBusiness ? Colors.amber : Colors.blue, // Золота/Синя галка
                    size: 18
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(postText, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 4),
                    Text('$likes'),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                  onPressed: () {},
                  icon: const Icon(Icons.card_giftcard, size: 16),
                  label: const Text('Подарунок'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- БЛОК 9/10: МОДУЛЬ ОПЛАТИ STRIPE ПІДПИСКИ ($1.5 / $49) ---
class SubscriptionService {
  static Future<void> buySubscription(BuildContext context, String priceId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/create-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': '123',
          'email': 'user@voidgram.com',
          'priceId': priceId,
        }),
      );

      final data = jsonDecode(response.body);
      final String clientSecret = data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Voidgram Verification',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вітаємо! Статус верифікації успішно активовано.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка підписки: $e')),
      );
    }
  }
}

// --- БЛОК 10/10: МОДУЛЬ WEBRTC ВІДЕОДЗВІНКІВ ---
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  Future<void> _initMedia() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = _localStream;
    setState(() {});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          Positioned(
            right: 20,
            top: 40,
            width: 110,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.call_end),
              ),
            ),
          )
        ],
      ),
    );
  }
}
// ==========================================
// VOIDGRAM FLUTTER MOBILE APP (ЧАСТИНА 2)
// ==========================================

// --- БЛОК 16/20: ЕКРАН БІЗНЕС-ПРОФІЛЮ ТА ВІТРИНИ ТОВАРІВ ---
class BusinessProfileScreen extends StatelessWidget {
  final String businessName;
  const BusinessProfileScreen({super.key, required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(businessName),
            const SizedBox(width: 5),
            const Icon(Icons.verified, color: Colors.amber, size: 20), // Gold Check
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка профілю
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF161925),
              child: Row(
                children: [
                  const CircleAvatar(radius: 35, backgroundColor: Colors.amber),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Офіційний бізнес-акаунт', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' 4.9 (128 відгуків)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Каталог товарів', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            // Сетка товаров
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.8,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF161925),
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(color: Colors.blueGrey, child: const Center(child: Icon(Icons.shopping_bag, size: 40))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Товар #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('\$29.99', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// --- БЛОК 17/20: МОДУЛЬ ПЕРЕГЛЯДУ STORIES ---
class StoryViewerScreen extends StatelessWidget {
  final String mediaUrl;
  const StoryViewerScreen({super.key, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
              return const Icon(Icons.image, size: 100, color: Colors.white24);
            }),
          ),
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text('User Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}


// --- БЛОК 18/20: ВНУТРІШНІЙ ГАМАНЕЦЬ (VOID COINS WALLET) ---
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Void Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161925),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: const [
                  Text('Ваш баланс', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 10),
                  Text('1,250 🪙', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Поповнити баланс монет', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: const Color(0xFF161925),
              leading: const Icon(Icons.monetization_on, color: Colors.amber),
              title: const Text('100 Void Coins'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('\$0.99')),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF161925),
              leading: const Icon(Icons.monetization_on, color: Colors.amber),
              title: const Text('500 Void Coins'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('\$4.99')),
            ),
          ],
        ),
      ),
    );
  }
}


// --- БЛОК 19/20: МОДУЛЬ СТВОРЕННЯ КАНАЛІВ ТА ГРУП ---
class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Створити канал')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Назва каналу', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Опис каналу', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                onPressed: () {
                  // Покликати API /api/channels/create
                  Navigator.pop(context);
                },
                child: const Text('Створити', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}


// --- БЛОК 20/20: ВІДГУКИ ПРО БІЗНЕС (BUSINESS REVIEWS COMPONENT) ---
class BusinessReviewsWidget extends StatelessWidget {
  const BusinessReviewsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xFF161925),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Row(
              children: const [
                Text('Клієнт ', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.star, color: Colors.amber, size: 14),
                Icon(Icons.star, color: Colors.amber, size: 14),
                Icon(Icons.star, color: Colors.amber, size: 14),
                Icon(Icons.star, color: Colors.amber, size: 14),
                Icon(Icons.star, color: Colors.amber, size: 14),
              ],
            ),
            subtitle: const Text('Чудовий сервіс та швидка доставка товарів! Рекомендую.'),
          ),
        );
      },
    );
  }
}
// ==========================================
// VOIDGRAM FLUTTER MOBILE APP (ЧАСТИНА 3)
// ==========================================

// --- БЛОК 27/30: ЕКРАН ПРЯМОЇ ТРАНСЛЯЦІЇ (LIVE STREAM VIEW) ---
class LiveStreamScreen extends StatelessWidget {
  final String streamTitle;
  const LiveStreamScreen({super.key, required this.streamTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Відео-потік трансляції
          Container(
            color: Colors.blueGrey.shade900,
            child: const Center(
              child: Icon(Icons.live_tv, size: 80, color: Colors.white24),
            ),
          ),
          
          // Плашка "LIVE" та глядачі
          Positioned(
            top: 50,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('1,420', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Чат донатів під час трансляції
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Коментар...',
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  backgroundColor: Colors.amber,
                  mini: true,
                  onPressed: () {
                    // Надіслати подарунок (Void Coins)
                  },
                  child: const Icon(Icons.card_giftcard, color: Colors.black),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


// --- БЛОК 28/30: НАЛАШТУВАННЯ ПРИВАТНОСТІ ТА БЕЗПЕКИ ---
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _hidePhoneNumber = true;
  bool _allowDirectCalls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Приватність та Безпека')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Приховати номер телефону'),
            subtitle: const Text('Користувачі бачитимуть лише ваш @username'),
            value: _hidePhoneNumber,
            onChanged: (val) => setState(() => _hidePhoneNumber = val),
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text('Дозволити прямі дзвінки'),
            subtitle: const Text('Приймати відеодзвінки від усіх користувачів'),
            value: _allowDirectCalls,
            onChanged: (val) => setState(() => _allowDirectCalls = val),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            title: const Text('Заблоковані користувачі'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}


// --- БЛОК 29/30: ЦЕНТР ПІДТРИМКИ ТА СКАРГ (REPORT SYSTEM) ---
class ReportDialog extends StatelessWidget {
  final String targetUserId;
  const ReportDialog({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161925),
      title: const Text('Подати скаргу'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Проросійська пропаганда'),
            onTap: () => Navigator.pop(context, 'propaganda'),
          ),
          ListTile(
            title: const Text('Спам або системний скам'),
            onTap: () => Navigator.pop(context, 'spam'),
          ),
          ListTile(
            title: const Text('Заборонений контент (NSFW)'),
            onTap: () => Navigator.pop(context, 'nsfw'),
          ),
        ],
      ),
    );
  }
}


// --- БЛОК 30/30: ГОЛОВНА НАВІГАЦІЯ ДОДАТКУ (BOTTOM NAVIGATION BAR) ---
class NavigationWrapperScreen extends StatefulWidget {
  const NavigationWrapperScreen({super.key});

  @override
  State<NavigationWrapperScreen> createState() => _NavigationWrapperScreenState();
}

class _NavigationWrapperScreenState extends State<NavigationWrapperScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CreateChannelScreen(),
    const WalletScreen(),
    const PrivacySettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF161925),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Стрічка'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Створити'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Гаманець'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Налаштування'),
        ],
      ),
    );
  }
}
// ==========================================
// VOIDGRAM FLUTTER MOBILE APP (ЧАСТИНА 4)
// ==========================================

// --- БЛОК 37/40: ЕКРАН БЛОКУВАННЯ (BANNED SCREEN) ---
class BannedUserScreen extends StatelessWidget {
  final String reason;
  const BannedUserScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text('Ваш акаунт заблоковано', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(reason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- БЛОК 38/40: ВІДЖЕТ ПІДТВЕРДЖЕННЯ ВЕРИФІКОВАНОГО СТАТУСУ ---
class VerificationBadgeWidget extends StatelessWidget {
  final bool isBusiness;
  const VerificationBadgeWidget({super.key, required this.isBusiness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isBusiness ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: isBusiness ? Colors.amber : Colors.blue),
          const SizedBox(width: 4),
          Text(
            isBusiness ? 'Business' : 'Verified',
            style: TextStyle(fontSize: 10, color: isBusiness ? Colors.amber : Colors.blue, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}

// --- БЛОК 39/40: МОДУЛЬ ЗАВАНТАЖЕННЯ МЕДІА З ЛІМІТОМ ВІДЕО ДО 60С ---
class MediaUploadService {
  static Future<bool> validateVideoDuration(int durationInSeconds) async {
    if (durationInSeconds > 60) {
      // Відео понад 60 секунд не дозволено публікувати у загальну стрічку
      return false;
    }
    return true;
  }
}

// --- БЛОК 40/40: ФІНАЛЬНА КОНФІГУРАЦІЯ ЗАПУСКУ СЕРВЕРА (ENV LOADER) ---
// Інструкція з запуску всього проекту:
// 1. Скопіювати блоки 1-5, 11-15, 21-24 у server.js
// 2. Виконати `npm install express socket.io stripe firebase-admin redis pg`
// 3. Запустити базу даних `psql -f schema.sql`
// 4. Запустити сервер `docker-compose up --build -d`
// 5. Зібрати Flutter-додаток (блоки 6-10, 16-20, 27-30, 37-40) командою `flutter build apk` / `flutter build ios`
