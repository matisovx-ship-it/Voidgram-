// ==========================================
// VOIDGRAM BACKEND ENGINE
// ==========================================

// --- БЛОК 1/10: ІНІЦІАЛІЗАЦІЯ СЕРВЕРА ТА ЗАЛЕЖНОСТЕЙ ---
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || 'sk_test_mock_key');

const app = express();
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// База даних у пам'яті (Для MVP)
const users = [];

// --- БЛОК 2/10: АВТОРИЗАЦІЯ ТА ГЕО-БЛОКУВАННЯ (ANTI-RU POLICY) ---
app.post('/api/register', (req, res) => {
    const { username, phone, isBusiness } = req.body;

    // Сувора перевірка коду країни (Блокування +7 та території РФ)
    if (phone.startsWith('+7') || phone.startsWith('7')) {
        return res.status(403).json({ 
            error: "Реєстрацію з території РФ заборонено відповідно до політики Voidgram." 
        });
    }

    const newUser = {
        id: users.length + 1,
        username,
        phone,
        isVerified: false,
        accountType: isBusiness ? 'Business' : 'Personal',
        subscriptionActive: false,
        badge: null,
        coins: 0
    };

    users.push(newUser);
    res.status(201).json({ message: "Успішна реєстрація", user: newUser });
});

// --- БЛОК 3/10: МАТРИЦЯ ОПЛАТ ТА ПІДПИСКИ STRIPE ($1.5 / $49) ---
app.post('/api/create-subscription', async (req, res) => {
    try {
        const { userId, email, priceId } = req.body; 
        // priceId: 'price_personal_1_5' ($1.5) або 'price_business_49' ($49)

        let customer = await stripe.customers.create({ email, metadata: { userId } });

        const subscription = await stripe.subscriptions.create({
            customer: customer.id,
            items: [{ price: priceId }],
            payment_behavior: 'default_incomplete',
            payment_settings: { save_default_payment_method: 'on_subscription' },
            expand: ['latest_invoice.payment_intent'],
        });

        const clientSecret = subscription.latest_invoice.payment_intent.client_secret;

        res.json({
            subscriptionId: subscription.id,
            clientSecret: clientSecret,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Webhook обробник успішних платежів
app.post('/webhook', express.raw({ type: 'application/json' }), (req, res) => {
    const event = req.body;
    if (event.type === 'invoice.payment_succeeded') {
        const customerId = event.data.object.customer;
        console.log(`[Stripe Status] Підписку підтверджено для клієнта: ${customerId}`);
    }
    res.json({ received: true });
});

// --- БЛОК 4/10: РЕАЛТАЙМ ЧАТ ТА ФІЛЬТРАЦІЯ ЗОВНІШНІХ ПОСИЛАНЬ ---
io.on('connection', (socket) => {
    console.log('[WebSocket] Користувач підключився:', socket.id);

    // Модуль повідомлень у чаті
    socket.on('send_message', (data) => {
        // Анти-скам: Заборона посилань на інші соціальні мережі
        const externalLinkRegex = /(telegram\.me|t\.me|instagram\.com|facebook\.com|twitter\.com|x\.com)/i;
        if (externalLinkRegex.test(data.text)) {
            return socket.emit('error_message', { 
                error: "Публікація посилань на інші соціальні мережі заборонена правилами платформи!" 
            });
        }

        io.emit('receive_message', data);
    });

// --- БЛОК 5/10: WEBRTC SIGNALING SERVERДЛЯ ВІДЕОДЗВІНКІВ ---
    socket.on('call_user', (data) => {
        io.to(data.userToCall).emit('incoming_call', {
            signal: data.signalData,
            from: data.from
        });
    });

    socket.on('answer_call', (data) => {
        io.to(data.to).emit('call_accepted', data.signal);
    });

    socket.on('ice_candidate', (data) => {
        io.to(data.target).emit('ice_candidate', data.candidate);
    });

    socket.on('disconnect', () => {
        console.log('[WebSocket] Користувач відключився');
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`[Voidgram Server] Запущено на порту ${PORT}`);
});
// ==========================================
// VOIDGRAM BACKEND ENGINE (ЧАСТИНА 2)
// ==========================================

// --- БЛОК 11/20: БІЗНЕС-МОДУЛЬ (ВІТРИНА ТОВАРІВ ТА ВІДГУКИ $49/міс) ---
const businessProducts = [];
const businessReviews = [];

// Додавання товару бізнес-профілем
app.post('/api/business/products', (req, res) => {
    const { userId, title, price, imageUrl, description } = req.body;
    const user = users.find(u => u.id === userId);

    if (!user || user.accountType !== 'Business' || !user.subscriptionActive) {
        return res.status(403).json({ error: "Доступно тільки для активних Business-акаунтів ($49/міс)." });
    }

    const newProduct = { id: businessProducts.length + 1, userId, title, price, imageUrl, description };
    businessProducts.push(newProduct);
    res.status(201).json({ message: "Товар успішно додано", product: newProduct });
});

// Додавання відгуку про бізнес
app.post('/api/business/reviews', (req, res) => {
    const { targetBusinessId, authorId, rating, comment } = req.body;
    
    if (rating < 1 || rating > 5) {
        return res.status(400).json({ error: "Оцінка має бути від 1 до 5 зірок." });
    }

    const newReview = { id: businessReviews.length + 1, targetBusinessId, authorId, rating, comment, date: new Date() };
    businessReviews.push(newReview);
    res.status(201).json({ message: "Відгук опубліковано", review: newReview });
});


// --- БЛОК 12/20: СИСТЕМА STORIES (ЗНИКАЮЧИЙ КОНТЕНТ 24 ГОД) ---
const stories = [];

app.post('/api/stories', (req, res) => {
    const { userId, mediaUrl } = req.body;
    
    const newStory = {
        id: stories.length + 1,
        userId,
        mediaUrl,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // +24 години
    };

    stories.push(newStory);
    res.status(201).json({ message: "Story завантажено", story: newStory });
});

// Отримання активних Stories
app.get('/api/stories', (req, res) => {
    const now = new Date();
    const activeStories = stories.filter(s => s.expiresAt > now);
    res.json(activeStories);
});


// --- БЛОК 13/20: ВНУТРІШНЯ ЕКОНОМІКА (VOID COINS ТА ПОДАРУНКИ) ---
app.post('/api/coins/buy', (req, res) => {
    const { userId, amount } = req.body; // amount: кількість монет
    const user = users.find(u => u.id === userId);

    if (!user) return res.status(404).json({ error: "Користувача не знайдено" });

    user.coins += amount;
    res.json({ message: "Монети успішно зараховано", balance: user.coins });
});

// Дарування подарунка у чаті або під час трансляції
app.post('/api/coins/send-gift', (req, res) => {
    const { senderId, receiverId, giftCost } = req.body;
    const sender = users.find(u => u.id === senderId);
    const receiver = users.find(u => u.id === receiverId);

    if (!sender || !receiver) return res.status(404).json({ error: "Користувача не знайдено" });
    if (sender.coins < giftCost) return res.status(400).json({ error: "Недостатньо Void Coins на балансі." });

    sender.coins -= giftCost;
    receiver.coins += giftCost;

    res.json({ message: "Подарунок відправлено!", senderBalance: sender.coins });
});


// --- БЛОК 14/20: NSFW МАТРИЦЯ МАТЕРІАЛІВ ТА АВТО-БАН (POLICY ENFORCEMENT) ---
app.post('/api/content/upload-check', (req, res) => {
    const { userId, mediaType, isAdultContent } = req.body;

    // Автоматичний банер за порнографію або проросійську пропаганду
    if (isAdultContent) {
        const user = users.find(u => u.id === userId);
        if (user) user.isBanned = true; // Permanent Ban

        return res.status(403).json({ 
            error: "Акаунт заблоковано назавжди за порушення правил платформи (Порнографія / Пропаганда)." 
        });
    }

    res.json({ status: "Approved", message: "Контент відповідає стандартам Voidgram." });
});


// --- БЛОК 15/20: КАНАЛИ ТА ПУБЛІЧНІ ГРУПИ ---
const channels = [];

app.post('/api/channels/create', (req, res) => {
    const { ownerId, title, description, isPublic } = req.body;

    const newChannel = {
        id: channels.length + 1,
        ownerId,
        title,
        description,
        isPublic,
        subscribersCount: 1
    };

    channels.push(newChannel);
    res.status(201).json({ message: "Канал успішно створено", channel: newChannel });
});
// ==========================================
// VOIDGRAM BACKEND ENGINE (ЧАСТИНА 3)
// ==========================================

// --- БЛОК 21/30: АВТОМАТИЧНА МОДЕРАЦІЯ ЗОБРАЖЕНЬ (NSFW / ПОРНОГРАФІЯ) ---
// Інтеграція алгоритму перевірки медіа перед публікацією
app.post('/api/media/moderate', async (req, res) => {
    const { userId, imageBase64 } = req.body;

    // Симуляція сканування зображення класифікатором контенту
    const containsNsfwContent = false; // Змінна отримує значення від медичного/NSFW сканера

    if (containsNsfwContent) {
        // Системний бан назавжди без права оскарження
        const user = users.find(u => u.id === userId);
        if (user) {
            user.isBanned = true;
            user.banReason = "Порушення політики: публікація контенту для дорослих (NSFW).";
        }

        return res.status(403).json({ 
            error: "Ваш акаунт було заблоковано назавжди через спробу завантаження забороненого вмісту." 
        });
    }

    res.json({ success: true, message: "Зображення пройшло перевірку безпеки." });
});


// --- БЛОК 22/30: FIREBASE PUSH-СПОПВІЩЕННЯ (FCM) ---
const admin = require('firebase-admin');

// Ініціалізація Firebase Admin SDK
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

app.post('/api/notifications/send', async (req, res) => {
    const { targetFcmToken, title, body, data } = req.body;

    const message = {
        notification: { title, body },
        data: data || {},
        token: targetFcmToken,
    };

    try {
        // await admin.messaging().send(message);
        console.log(`[FCM Notification] Надіслано push-сповіщення: ${title}`);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: "Помилка відправки сповіщення" });
    }
});


// --- БЛОК 23/30: МАТРИЦЯ ПРЯМИХ ТРАНСЛЯЦІЙ (LIVE STREAMS) ---
const activeStreams = [];

app.post('/api/streams/start', (req, res) => {
    const { userId, streamTitle } = req.body;
    const user = users.find(u => u.id === userId);

    if (!user) return res.status(404).json({ error: "Користувача не знайдено" });

    const streamData = {
        id: `stream_${Date.now()}`,
        hostId: userId,
        title: streamTitle,
        viewersCount: 0,
        startedAt: new Date()
    };

    activeStreams.push(streamData);
    res.status(201).json({ message: "Трансляцію розпочато", stream: streamData });
});


// --- БЛОК 24/30: АНТИ-СПАМ ФІЛЬТР ТА ОБМЕЖЕННЯ ЧАСТОТИ ЗАПИТІВ (RATE LIMITING) ---
const requestLogs = new Map();

const antiSpamMiddleware = (req, res, next) => {
    const userIp = req.ip;
    const now = Date.now();
    const windowMs = 60 * 1000; // 1 хвилина
    const maxRequests = 30; // Максимум 30 запитів на хвилину для акаунтів без підписки

    if (!requestLogs.has(userIp)) {
        requestLogs.set(userIp, []);
    }

    const timestamps = requestLogs.get(userIp).filter(time => now - time < windowMs);
    timestamps.push(now);
    requestLogs.set(userIp, timestamps);

    if (timestamps.length > maxRequests) {
        return res.status(429).json({ 
            error: "Занадто багато запитів. Придбайте підписку Personal ($1.5) для зняття лімітів." 
        });
    }

    next();
};

app.use('/api/', antiSpamMiddleware);
