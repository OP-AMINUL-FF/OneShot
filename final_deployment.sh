#!/bin/bash
# ----------------------------------------------------
# QUANTUM OMEGA GOD (v96.0) - ALL-IN-ONE DEPLOYMENT SCRIPT
# Executes all file creation and deployment steps safely.
# ----------------------------------------------------

echo "⚙️  STEP 1: Checking environment and variables..."
SERVICE_NAME="quantum-bot-service-final"
REGION="us-central1"
MEMORY="512Mi"

# Check for Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ ERROR: Google Cloud project ID not set. Please run 'gcloud init' first."
    exit 1
fi

echo "✅ Project ID detected: $PROJECT_ID"

# 1. Create/Navigate to the working directory
DIR_NAME="quantum-bot-gcr-final-v96"
mkdir -p "$DIR_NAME"
cd "$DIR_NAME" || exit

echo "✅ Working directory created: $PWD"

# 2. Create requirements.txt
echo -e "requests\npytelegrambotapi\nopenai\nFlask" > requirements.txt
echo "✅ requirements.txt created."

# 3. Create Dockerfile
cat > Dockerfile << EOF
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV PORT 8080
CMD ["python", "app.py"]
EOF
echo "✅ Dockerfile created."

# 4. Create app.py (The Flask server starter)
cat > app.py << EOF
import threading
from flask import Flask
import os
import sys
import time
import main 

app = Flask(__name__)

def run_bot_logic():
    try:
        main.keep_alive() 
        t_scanner = threading.Thread(target=main.auto_scanner)
        t_scanner.start()
        print("Bot Polling Listener Starting...")
        main.bot.infinity_polling()
    except Exception as e:
        print(f"CRITICAL BOT STARTUP ERROR: {e}")

@app.route('/')
def home():
    if not hasattr(app, 'bot_started'):
        app.bot_started = True
        print("Starting main bot thread...")
        threading.Thread(target=run_bot_logic).start()
        return "Quantum God initiated successfully on Cloud Run. Check Telegram for status."
    else:
        return "Quantum God is already running."

if __name__ == "__main__":
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
EOF
echo "✅ app.py created."

# 5. Create main.py (The core logic - v91.0 logic with all fixes)
cat > main.py << 'MAIN_EOF'
import os
import time
import json
import requests
import openai
import threading
from flask import Flask
import telebot
from telebot import types
import math
import traceback
import random

# --- 🔌 24/7 SERVER KEEP ALIVE ---
app = Flask('')

def run_server():
    try:
        app.run(host='0.0.0.0', port=8080)
    except: pass

def keep_alive():
    t = threading.Thread(target=run_server)
    t.start()

# --- ⚙️ কনফিগারেশন ---
TELEGRAM_BOT_TOKEN = "8364600719:AAH0KljC9hgj55AzAIQ7oXfva-Zw4Ii6_vY"
TELEGRAM_CHAT_ID = "5545859250"
OPENAI_API_KEY = "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"

# --- 🤖 বট সেটআপ ---
bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)

# --- 🌍 PAIRS ---
PAIRS = [
    "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "ADAUSDT",
    "DOGEUSDT", "PEPEUSDT", "SHIBUSDT", "WIFUSDT", "FLOKIUSDT", "BONKUSDT",
    "NOTUSDT", "FETUSDT", "RNDRUSDT", "SUIUSDT", "APTUSDT", "LINKUSDT",
    "AVAXUSDT", "MATICUSDT", "DOTUSDT", "UNIUSDT", "LTCUSDT", "BCHUSDT",
    "NEARUSDT", "FILUSDT", "ICPUSDT", "IMXUSDT", "ARBUSDT", "OPUSDT"
]
ALERT_COOLDOWN = 300 
alert_history = {}
SHOW_AI_LOGS = True 

# --- 🛠️ লগ রাইটার ফাংশন ---
def write_log(message):
    try:
        with open("error_log.txt", "a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")
    except: pass

# --- 🌐 ইন্টারনেট আপডেট ---
def update_coins_from_internet():
    global PAIRS
    try:
        url = "https://api.coingecko.com/api/v3/search/trending"
        response = requests.get(url, timeout=10).json()
        new_coins = [coin['item']['symbol'].upper() + "USDT" for coin in response['coins']]
        PAIRS = list(set(PAIRS + new_coins))
        return len(new_coins)
    except: 
        write_log("COINGECKO UPDATE FAILED: " + traceback.format_exc())
        return 0

# --- 🧠 মেমোরি সিস্টেম ---
def load_brain():
    if os.path.exists("brain.json"):
        try: return json.load(open("brain.json"))
        except: return {}
    return {}

def update_memory(symbol, price):
    brain = load_brain()
    if symbol not in brain: brain[symbol] = {"high": 0, "low": 999999.0}
    if price > brain[symbol]["high"]: brain[symbol]["high"] = price
    if price < brain[symbol]["low"]: brain[symbol]["low"] = price
    try: json.dump(brain, open("brain.json", 'w'), indent=4)
    except: pass
    return brain[symbol]

# --- 🧠 OpenAI Brain ---
def ask_chatgpt(symbol, price, rsi, trend, indicators):
    if "sk-" not in OPENAI_API_KEY: return "Offline", 50
    try:
        prompt = (f"Analyze {symbol}: Price ${price}, RSI {rsi}, Trend {trend}. Techs: {indicators}. Reply JSON: {{'reason': 'Short logic', 'confidence': 0-100}}")
        if SHOW_AI_LOGS:
            try: bot.send_message(TELEGRAM_CHAT_ID, f"📤 <b>AI Query:</b> {symbol}", parse_mode="HTML")
            except: pass
        client = openai.OpenAI(api_key=OPENAI_API_KEY)
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "system", "content": "You are a Risk Manager AI."}, {"role": "user", "content": prompt}],
            max_tokens=100
        )
        reply_text = response.choices[0].message.content
        if SHOW_AI_LOGS:
             try: bot.send_message(TELEGRAM_CHAT_ID, f"📥 <b>AI Reply:</b> {reply_text}", parse_mode="HTML")
             except: pass
        data = json.loads(reply_text)
        return data.get('reason', 'AI Checked'), data.get('confidence', 50)
    except: 
        write_log("GPT CALL FAILED: " + traceback.format_exc())
        return "AI Busy", 50

# --- 🔮 ম্যাথ প্যাকেজ (BULLETPROOF INDICATORS) 🔥 ---
MIN_DATA_POINTS = 20

def calculate_ema(prices, period):
    if len(prices) < MIN_DATA_POINTS: return prices[-1] if prices else 0
    multiplier = 2 / (period + 1); ema = sum(prices[:period]) / period
    for price in prices: ema = (price - ema) * multiplier + ema
    return ema

def calculate_rsi(prices, period=14):
    if len(prices) < MIN_DATA_POINTS: return 50
    gains, losses = [], [];
    for i in range(1, len(prices)): change = prices[i] - prices[i-1]; gains.append(max(0, change)); losses.append(max(0, -change))
    rs = sum(gains[-period:]) / sum(losses[-period:]) if sum(losses[-period:]) > 0 else 0
    return 100 - (100 / (1 + rs))

def calculate_macd(prices):
    if len(prices) < MIN_DATA_POINTS: return 0
    return calculate_ema(prices, 12) - calculate_ema(prices, 26)

def calculate_bollinger(prices, period=20):
    if len(prices) < MIN_DATA_POINTS: return 0, 0
    sma = sum(prices[-period:]) / period
    std = (sum([(x - sma) ** 2 for x in prices[-period:]]) / period) ** 0.5
    return sma + (2 * std), sma - (2 * std)

def calculate_fibonacci(highs, lows):
    if len(highs) < MIN_DATA_POINTS: return {"0.618": 0}
    h = max(highs); l = min(lows); diff = h - l
    return {"0.618": h - (diff * 0.618)}

def calculate_atr(highs, lows, closes, period=14):
    if len(highs) < MIN_DATA_POINTS: return 0
    tr_list = [];
    for i in range(1, len(closes)):
        hl = highs[i] - lows[i]; hc = abs(highs[i] - closes[i-1]); lc = abs(lows[i] - closes[i-1])
        tr_list.append(max(hl, hc, lc))
    return sum(tr_list[-period:]) / period if tr_list else 0

def calculate_vwap(closes, volumes):
    if len(closes) < MIN_DATA_POINTS: return closes[-1] if closes else 0
    pv = sum([c * v for c, v in zip(closes, volumes)])
    v = sum(volumes)
    return pv / v if v > 0 else closes[-1]

def detect_pattern(o, h, l, c):
    if all(x == 0 for x in [o, h, l, c]): return "None"
    body = abs(c - o)
    if (min(c, o) - l) > (body * 2): return "Hammer"
    if (h - max(c, o)) > (body * 2): return "Shooting Star"
    return "None"

def get_coingecko_price(symbol):
    """ সেকেন্ডারি API: CoinGecko থেকে প্রাইস নেবে """
    try:
        coin_id = symbol.replace("USDT", "").lower() 
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={coin_id}&vs_currencies=usd"
        res = requests.get(url, timeout=5).json()
        return res[coin_id]['usd']
    except: return 0

def get_json_safely(response):
    """ JSON Parsing Failure Handling """
    try:
        return response.json()
    except requests.exceptions.JSONDecodeError:
        write_log(f"JSONDecodeError: Response status: {response.status_code}")
        return {"error": "Invalid JSON response"}

def get_data(symbol, market="BINANCE"):
    """ CRITICAL DATA FETCH FUNCTION """
    DEFAULT_RETURN = 0, 0, 0, 0, 0, 0, 0, {}, "None", None, [], 0 # 13 safe values
    
    try:
        if market == "BINANCE":
            url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval=15m&limit=100"
        elif market == "BYBIT":
            url = f"https://api.bybit.com/v5/market/kline?category=linear&symbol={symbol}&interval=15&limit=100"
        else:
            raise Exception("Invalid market source.")
            
        session = requests.Session()
        session.headers.update({'Cache-Control': 'no-cache'})
        response = session.get(url, timeout=10)
        
        res = get_json_safely(response)

        # Validation 1: Check for API Error Message
        if isinstance(res, dict) and ('msg' in res or 'retCode' in res or 'error' in res): 
            error_msg = res.get('msg', res.get('retMsg', res.get('error', 'API Blocked')))
            raise Exception(f"{market} API Error: {error_msg}")
        
        # Data Extraction (Abstracted)
        kline_data = []
        if market == "BINANCE":
            kline_data = res
        elif market == "BYBIT":
            kline_data = res.get('result', {}).get('list', [])
            kline_data.reverse()
        
        # Validation 2: Check for Minimum Data 
        if not isinstance(kline_data, list) or len(kline_data) < 50:
            raise Exception(f"{market} Incomplete kline data received (Got {len(kline_data)} candles).")
            
        # Data Conversion (Protected Unpacking)
        closes, highs, lows, opens, volumes = [], [], [], [], []
        for k in kline_data:
            try:
                closes.append(float(k[4])); highs.append(float(k[2])); lows.append(float(k[3])); opens.append(float(k[1])); volumes.append(float(k[5]))
            except (IndexError, ValueError): 
                write_log(f"{market} Data Struct/Type Error: {k}")
                raise Exception(f"{market} Data Struct Error: Invalid kline data.")


        curr_p = closes[-1]; update_memory(symbol, curr_p)
        
        # Indicators
        rsi, low, up = calculate_bollinger(closes); ema = calculate_ema(closes, 50); macd = calculate_macd(closes)
        fib = calculate_fibonacci(highs, lows); atr = calculate_atr(highs, lows, closes)
        pat = detect_pattern(opens[-1], highs[-1], lows[-1], closes[-1]); vwap = calculate_vwap(closes, volumes)
        
        return curr_p, rsi, low, up, ema, macd, atr, fib, pat, None, volumes, vwap
        
    except Exception as e: 
        write_log(f"DATA FETCH CRASH from {market} for {symbol}: {e}")
        return DEFAULT_RETURN

# --- 🧠 আলটিমেট অ্যানালাইসিস ---
def analyze(symbol, price, rsi, low, up, ema, macd, atr, fib, pat, brain, volumes, vwap):
    if price == 0: return 0, [f"Error: Data Fetch Failed. Check Log."], 0, 0, "N/A"
    
    score = 0; reason = []
    
    if rsi < 30: score += 20; reason.append(f"📉 RSI Oversold ({int(rsi)})")
    elif rsi > 70: score -= 20; reason.append(f"📈 RSI Overbought ({int(rsi)})")
    
    if price <= low and low != 0: score += 10; reason.append("📉 BB Support")
    elif price >= up and up != 0: score -= 10; reason.append("📈 BB Resistance")
    
    if price > ema and ema != 0: score += 10; reason.append("🚀 Trend UP")
    elif price < ema and ema != 0: score -= 10; reason.append("🔻 Trend DOWN")
    
    if macd > 0: score += 10; reason.append("🚀 Momentum UP")
    else: score -= 10; reason.append("🔻 Momentum DOWN")
    
    fib618 = fib.get("0.618", 0)
    if fib618 != 0 and abs(price - fib618)/price < 0.005: score += 20; reason.append("✨ Golden Pocket (0.618)")
    if vwap != 0 and price < vwap: score += 10; reason.append("🐋 Below VWAP (Cheap)")
    elif vwap != 0: score -= 10
    
    if pat != "None": score += 10; reason.append(f"🕯️ {pat} Pattern")

    math_score = max(-100, min(100, score))
    
    # --- RISK MANAGEMENT (SL/TP) ---
    sl, tp, time_est = 0, 0, "N/A"
    if atr > 0:
        if math_score > 0: sl = price - (atr * 2); tp = price + (atr * 3); time_est = f"{int((tp-price)/(atr*0.5)*15)}m"
        else: sl = price + (atr * 2); tp = price - (atr * 3); time_est = f"{int((price-tp)/(atr*0.5)*15)}m"

    # AI Integration
    ai_conf = 0
    if abs(math_score) >= 50:
        trend = "UP" if math_score > 0 else "DOWN"
        inds = f"RSI:{int(rsi)}, MACD:{macd:.2f}, VWAP:{vwap:.4f}"
        ai_reason, ai_conf = ask_chatgpt(symbol, price, int(rsi), trend, inds)
        
        if math_score > 0: score += (ai_conf * 0.4)
        else: score -= (ai_conf * 0.4)
        reason.append(f"🧠 AI: {ai_reason}")

    return score, reason, sl, tp, time_est

# --- ⌨️ কি-বোর্ড মেনু তৈরি ---
def get_main_menu():
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    btn1 = types.KeyboardButton('📊 Live Market')
    btn2 = types.KeyboardButton('🎯 90% Sure Shot')
    btn3 = types.KeyboardButton('🌐 Update Coins')
    btn4 = types.KeyboardButton('🧠 Chat Log: ON/OFF')
    btn5 = types.KeyboardButton('🛠️ Get Error Log') 
    markup.add(btn1, btn2, btn3, btn4, btn5)
    return markup

# --- 🎮 বাটন হ্যান্ডলার ---
@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.send_message(message.chat.id, "👋 <b>Welcome! All systems online.</b>", reply_markup=get_main_menu(), parse_mode="HTML")

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    try:
        global SHOW_AI_LOGS, PAIRS
        
        if message.text == '🌐 Update Coins':
            bot.send_message(message.chat.id, "🌐 <b>Fetching Trending Coins...</b>", parse_mode="HTML")
            count = update_coins_from_internet()
            bot.send_message(message.chat.id, f"✅ <b>Updated!</b> {count} new coins added.", reply_markup=get_main_menu(), parse_mode="HTML")

        elif message.text == '🛠️ Get Error Log':
            try:
                with open("error_log.txt", "r") as f: log_content = f.read()
                if not log_content: log_content = "Log file is empty. No recent errors."
                bot.send_message(message.chat.id, f"🛠️ <b>ERROR LOG (Last 1500 Chars):</b>\n<code>{log_content[-1500:]}</code>", reply_markup=get_main_menu(), parse_mode="HTML")
            except FileNotFoundError:
                bot.send_message(message.chat.id, "🛠️ Error Log file not found yet.", reply_markup=get_main_menu(), parse_mode="HTML")

        elif message.text == '📊 Live Market':
            bot.send_message(TELEGRAM_CHAT_ID, "🔍 <b>Scanning ALL PAIRS (Top 7)...</b>", parse_mode="HTML")
            all_report = "<b>📊 FULL MARKET STATUS:</b>\n\n"
            
            for sym in PAIRS[:7]:
                p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(sym, market="BINANCE") # 1. Try Binance
                
                market_source = "Binance"
                if p == 0: 
                    p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(sym, market="BYBIT") # 2. Try Bybit
                    market_source = "Bybit"
                
                if p == 0: 
                    cg_price = get_coingecko_price(sym)
                    if cg_price > 0:
                        line = f"<b>{sym.replace('USDT','')}:</b> ${cg_price:.4f} (CoinGecko) | 🔴 Analysis Blocked\n"
                    else:
                        line = f"<b>{sym.replace('USDT','')}:</b> 🔴 All APIs Failed.\n"
                else:
                    trend = "🟢 Bull" if p > e else "🔴 Bear"
                    signal_icon = "🔥" if rsi < 30 or rsi > 70 else "⚪"
                    line = f"<b>{sym.replace('USDT','')}:</b> ${p:.4f} ({market_source}) | RSI {int(rsi)} {signal_icon} | {trend}\n"
                
                all_report += line
                time.sleep(1.0) # Slow Down Requests
            
            bot.send_message(message.chat.id, all_report, parse_mode="HTML")
            bot.send_message(message.chat.id, "✅ Full market snapshot delivered.", reply_markup=get_main_menu(), parse_mode="HTML")
            
        elif message.text == '🎯 90% Sure Shot':
            bot.send_message(message.chat.id, "💎 <b>Hunting 90%+ Signals...</b>", parse_mode="HTML")
            found = False
            for sym in PAIRS:
                p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(sym, market="BINANCE")
                if p == 0: 
                    p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(sym, market="BYBIT")
                
                if p == 0: continue
                score, reason, sl, tp, tm = analyze(sym.replace("USDT",""), p, rsi, l, u, e, m, a, fib, pat, b)
                
                if abs(score) >= 90:
                    found = True
                    act = "⬆️ TAKE UP (LONG) 🟢" if score > 0 else "⬇️ TAKE DOWN (SHORT) 🔴"
                    reason_txt = "\n".join(reason)
                    
                    plan = (f"🔥 <b>90% SURE SHOT: {sym.replace('USDT','')}</b>\n\n"
                            f"💎 <b>ACTION:</b> {act}\n"
                            f"🧠 Conf: {int(score)}%\n\n"
                            f"🛡️ <b>PLAN:</b>\n"
                            f"SL: ${sl:.4f} | TP: ${tp:.4f}\n"
                            f"⏳ Est. Time: {tm}\n\n"
                            f"🤖 <b>Logic:</b>\n{reason_txt}")
                    
                    bot.send_message(message.chat.id, plan, reply_markup=get_main_menu(), parse_mode="HTML")
                
                time.sleep(0.3)

            if not found: bot.send_message(message.chat.id, "😴 No 90% signals now. Capital Safe.", reply_markup=get_main_menu(), parse_mode="HTML")

        elif message.text == '🧠 Chat Log: ON/OFF':
            SHOW_AI_LOGS = not SHOW_AI_LOGS
            status = "VISIBLE ✅" if SHOW_AI_LOGS else "HIDDEN ❌"
            bot.send_message(message.chat.id, f"🧠 <b>AI Chat Logs: {status}</b>", reply_markup=get_main_menu(), parse_mode="HTML")

    except Exception as e:
        write_log(f"HANDLE MESSAGE CRASH: {e}\n{traceback.format_exc()}")
        bot.send_message(message.chat.id, "❌ <b>CRITICAL ERROR!</b>\nSystem crashed. Check log.", reply_markup=get_main_menu(), parse_mode="HTML")

# --- 🔄 অটো স্ক্যানার (AUTO ALERT) 🔄 ---
def auto_scanner():
    global alert_history
    print("Auto Alert Scanner Started...")
    update_coins_from_internet()
    
    try:
        bot.send_message(TELEGRAM_CHAT_ID, "✅ <b>ULTIMATE BOT ONLINE!</b>\nAuto Alert Active (80%+).", reply_markup=get_main_menu(), parse_mode="HTML")
    except: pass

    while True:
        try:
            for symbol in PAIRS[:7]: # Scan top 7 pairs automatically
                p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(symbol, market="BINANCE")
                if p == 0: 
                    p, rsi, l, u, e, m, a, fib, pat, b, v, vw = get_data(symbol, market="BYBIT")
                
                if p == 0: continue
                score, reason, sl, tp, tm = analyze(symbol.replace("USDT",""), p, rsi, l, u, e, m, a, fib, pat, b)
                
                if abs(score) >= 80:
                    last = alert_history.get(symbol, 0)
                    if time.time() - last > 3600: # Cooldown: 1 hour
                        act = "LONG 🟢" if score > 0 else "SHORT 🔴"
                        reason_txt = "\n".join(reason)
                        msg = (f"🔥 <b>AUTO ALERT: {symbol.replace('USDT','')}</b>\n\n"
                               f"💎 <b>ACTION:</b> {act}\n"
                               f"🧠 Score: {int(score)}%\n"
                               f"🛡️ <b>PLAN:</b> SL: ${sl:.4f} | TP: ${tp:.4f}\n"
                               f"⏳ Est. Time: {tm}\n\n"
                               f"🤖 <b>Logic:</b>\n{reason_txt}")
                        
                        try:
                            requests.post(f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage", 
                                          json={"chat_id": TELEGRAM_CHAT_ID, "text": msg, "parse_mode": "HTML"})
                            alert_history[symbol] = time.time()
                        except: pass
                
                time.sleep(1) # Slow down auto scan

            time.sleep(60)
        except Exception as e:
            write_log(f"AUTO SCANNER LOOP CRASH: {e}\n{traceback.format_exc()}")
            time.sleep(10)

# --- 🏁 মেইন ---
# NOTE: This block is commented out/removed for GCR deployment (app.py handles startup)
# if __name__ == "__main__":
#     keep_alive()
#     t = threading.Thread(target=auto_scanner)
#     t.start()
#     while True:
#         try:
#             bot.infinity_polling(timeout=10, long_polling_timeout=5)
#         except Exception as e:
#             print(f"Polling Crash: {e}. Restarting...")
#             time.sleep(2)