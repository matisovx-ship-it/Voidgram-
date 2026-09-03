-- ==========================================
-- VOIDGRAM DATABASE SCHEMA (POSTGRESQL)
-- ==========================================

-- --- БЛОК 31/40: ТАБЛИЦІ КОРИСТУВАЧІВ ТА ПІДПИСОК ---
CREATE TYPE account_type_enum AS ENUM ('Personal', 'Business');
CREATE TYPE badge_type_enum AS ENUM ('Blue', 'Gold');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    account_type account_type_enum DEFAULT 'Personal',
    is_verified BOOLEAN DEFAULT FALSE,
    badge_type badge_type_enum DEFAULT NULL,
    coins_balance INT DEFAULT 0,
    is_banned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    stripe_subscription_id VARCHAR(255) UNIQUE NOT NULL,
    plan_type VARCHAR(50) NOT NULL, -- 'personal_1_5' або 'business_49'
    status VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- --- БЛОК 32/40: ТАБЛИЦІ КОНТЕНТУ (ПОСТИ, STORIES, КАНАЛИ) ---
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INT REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    video_duration_sec INT CHECK (video_duration_sec <= 60), -- Максимум 60 секунд для стрічки
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stories (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours')
);

CREATE TABLE channels (
    id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- --- БЛОК 33/40: ТАБЛИЦІ E-COMMERCE ТА ВІДГУКІВ ДЛЯ БІЗНЕСУ ---
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    business_id INT REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE business_reviews (
    id SERIAL PRIMARY KEY,
    business_id INT REFERENCES users(id) ON DELETE CASCADE,
    author_id INT REFERENCES users(id) ON DELETE CASCADE,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- --- БЛОК 34/40: ТАБЛИЦІ МЕСЕНДЖЕРА ТА ВНУТРІШНІХ ОПЕРАЦІЙ ---
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INT REFERENCES users(id) ON DELETE CASCADE,
    channel_id INT REFERENCES channels(id) ON DELETE CASCADE,
    message_text TEXT,
    media_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gift_transactions (
    id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INT REFERENCES users(id) ON DELETE CASCADE,
    coins_amount INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
