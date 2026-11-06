# QuickClip 📋

<div dir="rtl">

اپلیکیشن iOS برای ذخیره‌ی سریع متن‌های پرکاربرد و **کپی خودکار آن‌ها در کلیپ‌بورد با یک لمس** — همان کاری که اندروید راحت انجام می‌دهد، اما برای iOS!

این ریپو **دو نسخه** دارد:

1. 📱 **اپ نیتیو iOS** با SwiftUI (نیازمند مک + Xcode)
2. 🌐 **نسخه وب PWA** در پوشه‌ی `webapp/` — **بدون نیاز به مک!** با GitHub Pages آنلاین می‌شود و مستقیم روی آیفون نصب می‌شود (بخش «بدون مک» را ببینید)

هر دو نسخه رابط کاربری **انگلیسی** و طراحی **مینیمال به سبک اپل** دارند.

</div>

---

## ✨ Features

- **QuickClip Keyboard** — کیبورد اختصاصی QuickClip در **هر اپی**: بالای کیبورد سیستم، چیپ‌های اسنیپت‌هات نمایش داده می‌شن و با یک لمس، متن مستقیم داخل فیلد تایپ می‌شه — نه کپی لازمه نه پیست! حتی با دکمه‌ی ＋ می‌تونی **همون‌جا متن جدید ذخیره کنی** (از کلیپ‌بورد یا از همون فیلدی که توش تایپ کردی)
- **Copy on Tap** — با هر لمس روی هر اسنیپت، محتوای آن فوراً در کلیپ‌بورد ذخیره می‌شود (با هپتیک و پیام تأیید)
- **New from Clipboard** — هر متنی که الان روی کلیپ‌بورد دارید را با یک دکمه وارد اپ کنید
- **Paste from Clipboard** — داخل صفحه‌ی ویرایش هم دکمه‌ی چسباندن سریع وجود دارد
- **Categories** — دسته‌بندی اسنیپت‌ها با رنگ و آیکون دلخواه + فیلتر چیپی در صفحه‌ی اصلی
- **Search** — جستجوی زنده در عنوان و محتوای اسنیپت‌ها
- **Pin to Top** — سنجاق کردن اسنیپت‌های پرکاربرد در بالای لیست
- **Auto-clear Clipboard** — پاک شدن خودکار کلیپ‌بورد بعد از ۳۰ ثانیه تا ۵ دقیقه (حریم خصوصی)
- **Sorting** — مرتب‌سازی بر اساس تاریخ، عنوان، بیشترین کپی یا آخرین کپی
- **Copy Counter** — تعداد دفعات کپی هر اسنیپت نمایش داده می‌شود
- **ShareLink** — اشتراک‌گذاری متن از منوی طولانی‌فشردن (Long Press)
- **ذخیره‌سازی محلی** — همه‌ی داده‌ها در یک فایل JSON داخل حافظه‌ی خود گوشی؛ هیچ داده‌ای از گوشی خارج نمی‌شود

## 📱 Screens

| Tab | توضیح |
| --- | --- |
| **Snippets** | لیست اصلی اسنیپت‌ها با فیلتر دسته‌ها، جستجو، کپی تک‌لمسی، سواپ اکشن‌ها |
| **Categories** | ساخت، ویرایش و حذف دسته‌ها با انتخاب رنگ و آیکون |
| **Settings** | تنظیمات کپی، هپتیک، پاک‌سازی خودکار کلیپ‌بورد، مرتب‌سازی و مدیریت داده‌ها |

## 🛠 Requirements

- نسخه iOS: macOS + **Xcode 16 یا جدیدتر** (پروژه با فرمت جدید `objectVersion 77`)
- نسخه وب: فقط یک مرورگر — **به مک نیازی نیست!**
- هدف اجرای iOS: **iOS 16.0 به بالا** (آیفون و آیپد)
- برای نصب روی گوشی واقعی: یک **Apple ID رایگان** کافی است

## 📲 No Mac? Two Ways to Install (بدون مک)

<div dir="rtl">

### راه ۱ — نسخه وب PWA (ساده‌ترین، پیشنهادی ✨)

بعد از push کردن ریپو روی GitHub، اپ وب به صورت خودکار روی **GitHub Pages** منتشر می‌شود:

1. در GitHub بروید به: **Settings → Pages → Source: GitHub Actions** (فقط بار اول)
2. بعد از اجرای workflow منتظر بمانید — آدرس اپ می‌شود:
   `https://<username>.github.io/quickclip/`
3. در آیفون آن آدرس را با **Safari** باز کنید
4. دکمه‌ی **Share → Add to Home Screen** بزنید — تمام! اپ با آیکون اختصاصی و تمام‌صفحه مثل اپ واقعی اجرا می‌شود و آفلاین هم کار می‌کند

> نکته: داده‌ها در localStorage همان مرورگر ذخیره می‌شوند؛ اگر «پاک کردن داده‌های سافاری» کنید، داده‌ها از بین می‌روند.

### راه ۲ — نصب اپ نیتیو iOS با فایل IPA (نیازمند ویندوز + کابل)

با **GitHub Actions** اپ iOS بدون مک بیلد می‌شود:

1. بعد از push، در تب **Actions** ریپو، workflow با نام «Build iOS (unsigned IPA)» اجرا می‌شود (حدود ۱۰ تا ۲۰ دقیقه)
2. نتیجه در دو جا قرار می‌گیرد: تب **Actions → artifacts** و بخش **Releases** — فایل `QuickClip-unsigned.ipa` را دانلود کنید
3. روی ویندوز، ابزار [Sideloadly](https://sideloadly.io) یا [AltStore](https://altstore.io) را نصب کنید
4. آیفون را با کابل به ویندوز وصل کنید، فایل IPA را در Sideloadly بگذارید، Apple ID خود را وارد و Install بزنید
5. در گوشی: **Settings → General → VPN & Device Management** → اعتماد (Trust) به گواهی

> محدودیت: امضای رایگان Apple ID بعد از **۷ روز** منقضی می‌شود و باید دوباره امضا/نصب کنید. با اکانت Apple Developer پولی (۹۹ دلار/سال) محدودیت برداشته می‌شود.

</div>

## ⌨️ QuickClip Keyboard (Type Anywhere)

اپ iOS یک **کیبورد اکستنشن** هم دارد — بعد از نصب، یک بار فعالش کن و از آن به بعد در هر اپی (واتس‌اپ، تلگرام، ایمیل، …) اسنیپت‌هات بالای کیبورد هستند:

1. روی گوشی برو به: **Settings → General → Keyboard → Keyboards → Add New Keyboard…** → انتخاب **QuickClip**
2. در هر اپی که داری تایپ می‌کنی، کلید **🌐** را نگه دار (یا بزن) و کیبورد **QuickClip** را انتخاب کن
3. روی چیپ اسنیپت بزن — متن بلافاصله داخل فیلد تایپ درج می‌شود؛ **نه کپی لازم است نه پیست**
4. دکمه‌ی ☰ لیست کامل با پیش‌نمایش محتوا را نشان می‌دهد و دکمه‌ی 🌐 داخل کیبورد، برمی‌گرداند به کیبورد قبلی
5. **ذخیره از خود کیبورد:** دکمه‌ی **＋** را بزن — «Save from Clipboard» هر چیزی که کپی کرده‌ای را ذخیره می‌کند و «Save Typed Text» متن همان فیلدی را که داری تایش تایپ می‌کنی. اسنیپت‌های جدید بلافاصله در چیپ‌ها می‌آیند و با باز کردن اپ، به لیست اصلی اضافه می‌شوند (قابل ویرایش، دسته‌بندی و سنجاق)

> نکته‌ها: اسنیپت‌های کیبورد خودکار سینک می‌شوند (اول سنجاق‌شده‌ها، بعد پرکپی‌ترین‌ها — تا ۲۴ تا). برای درج متن و «Save Typed Text» نیازی به **Full Access** نیست؛ فقط «Save from Clipboard» به آن نیاز دارد (Settings → Keyboards → QuickClip → Allow Full Access). کیبورد به اینترنت دسترسی ندارد — همه‌چیز داخل گوشی می‌ماند.

## 🚀 Run

```bash
git clone https://github.com/<username>/quickclip.git
cd quickclip
open QuickClip.xcodeproj
```

1. در Xcode تارگت **QuickClip** را انتخاب کنید
2. در تب **Signing & Capabilities** گزینه‌ی **Team** را روی Apple ID شخصی خود بگذارید
3. شبیه‌ساز (مثلاً iPhone 16) یا گوشی خود را انتخاب و **Cmd + R** بزنید

> نکته: bundle identifier به صورت `com.quickclip.app` است؛ در صورت نیاز از تب Signing تغییرش دهید.

## 📲 Install on a Real iPhone (Free)

با Apple ID رایگان می‌توانید اپ را روی گوشی خودتان نصب کنید (امضای Personal Team — اپ بعد از **۷ روز** دوباره باید نصب شود؛ با اکانت توسعه‌دهنده‌ی پولی این محدودیت برداشته می‌شود):

1. گوشی را با کابل به مک وصل کنید
2. در Xcode در بخش Signing گزینه‌ی Team را انتخاب کنید
3. در گوشی: **Settings → General → VPN & Device Management** و اعتماد (Trust) به گواهی توسعه‌دهنده
4. Run بزنید — تمام!

## ☁️ Publish to GitHub

پروژه با یک کامیت اولیه و شاخه‌ی `main` آماده است. کافی است:

1. در [github.com/new](https://github.com/new) یک ریپازیتوری خالی بسازید (بدون README)
2. سپس:

```bash
cd quickclip
git remote add origin https://github.com/<username>/quickclip.git
git push -u origin main
```

<div dir="rtl">

بعد از هر push، دو workflow به صورت خودکار اجرا می‌شوند:

| Workflow | کار | خروجی |
| --- | --- | --- |
| **Build iOS (unsigned IPA)** | بیلد اپ iOS روی سرور macOS گیت‌هاب | فایل `QuickClip-unsigned.ipa` در Actions و Releases |
| **Deploy Web App (GitHub Pages)** | انتشار نسخه وب | اپ آنلاین روی `<username>.github.io/quickclip` |

برای فعال‌سازی Pages فقط یک بار: **Settings → Pages → Source: GitHub Actions**

</div>

## 🗂 Project Structure

```
QuickClip/
├── .github/workflows/
│   ├── build-ios.yml              # بیلد خودکار IPA با GitHub Actions
│   └── deploy-pages.yml           # انتشار نسخه وب روی GitHub Pages
├── QuickClip.xcodeproj/
├── QuickClip/                     # اپ نیتیو iOS (SwiftUI)
│   ├── QuickClipApp.swift          # نقطه‌ی ورود (@main)
│   ├── Models/
│   │   ├── Snippet.swift           # مدل اسنیپت + داده‌های نمونه
│   │   ├── SnippetCategory.swift   # مدل دسته‌بندی
│   │   └── AppSettings.swift       # تنظیمات + گزینه‌های مرتب‌سازی
│   ├── Store/
│   │   └── SnippetStore.swift      # ذخیره‌سازی JSON + موتور کپی کلیپ‌بورد
│   ├── Support/
│   │   ├── Haptics.swift           # بازخورد لمسی
│   │   └── ColorHex.swift          # تبدیل رنگ هگز
│   ├── Views/
│   │   ├── RootTabView.swift       # TabView اصلی + Toast
│   │   ├── Snippets/               # لیست، ردیف و ویرایشگر اسنیپت
│   │   ├── Categories/             # مدیریت دسته‌ها
│   │   ├── Settings/               # تنظیمات
│   │   └── Components/             # Toast و Empty State
│   ├── QuickClip.entitlements      # App Group برای سینک با کیبورد
│   └── Assets.xcassets/            # آیکون اپ و رنگ اصلی
├── QuickClipKeyboard/              # کیبورد اکستنشن (تایپ یک‌لمسی در هر اپ)
│   ├── KeyboardViewController.swift  # رابط کیبورد (چیپ‌ها + لیست)
│   ├── Info.plist                    # تعریف اکستنشن کیبورد
│   └── QuickClipKeyboard.entitlements # App Group مشترک با اپ
└── webapp/                         # نسخه وب PWA (بدون نیاز به مک)
    ├── index.html                  # ساختار اپ
    ├── style.css                   # استایل مینیمال اپل
    ├── app.js                      # منطق اپ (کپی، دسته‌ها، localStorage)
    ├── manifest.json               # تعریف PWA
    ├── sw.js                       # سرویس‌ورکر (کار آفلاین)
    └── icons/                      # آیکون‌های PWA
```

## ⚙️ Key Implementation Notes

- کپی در کلیپ‌بورد با `UIPasteboard.general` انجام می‌شود؛ حالت Auto-clear از قابلیت `expirationDate` (iOS 16+) استفاده می‌کند
- کیبورد اکستنشن از طریق **App Group** (`group.com.quickclip.app`) سینک می‌شود: اپ بعد از هر تغییر، لیست اسنیپت‌ها را در `UserDefaults` مشترک می‌نویسد و کیبورد با `textDocumentProxy.insertText` متن را درج می‌کند
- همه‌ی داده‌ها به صورت خودکار بعد از هر تغییر در `Documents/quickclip-data.json` ذخیره می‌شوند
- نسخه وب از `navigator.clipboard.writeText` با fallback به `execCommand` استفاده می‌کند و داده‌ها را در `localStorage` نگه می‌دارد
- معماری ساده و بدون وابستگی خارجی — مناسب برای یادگیری SwiftUI و توسعه وب

## 🌐 Web App Notes

- آدرس نهایی بعد از انتشار: `https://<username>.github.io/quickclip/`
- کار کاملاً **آفلاین** (سرویس‌ورکر کش می‌کند)
- روی اندروید هم نصب می‌شود (Chrome → Add to Home Screen) — یعنی یه خروجی اندروید هم مجانی گرفتید!
- برای دریافت متنی که روی کلیپ‌بورد است، دکمه‌ی «Paste from Clipboard» در صفحه‌ی ویرایش، سافاری ابتدا اجازه می‌پرسد

## 📄 License

MIT — آزاد برای استفاده، تغییر و انتشار.
