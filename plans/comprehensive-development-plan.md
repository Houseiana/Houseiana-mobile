# خطة التطوير الشاملة لمشروع Houseiana Mobile

## Prompt المستخدم (Original Request)

```
احنا دلوقتى عندنا مشروع موبايل فلاتر Flutter موجود بالفعل وهو مرتبط على نفس الـ API الخاصة بمشروع الويب Houseiana-Holidays-Homes-main-web والمشروعين موجودين جنب بعض في نفس مجلد الـ workspace

المطلوب منك تعمل خطة تطوير شاملة ومتكاملة لمشروع الموبايل بحيث يكون النسخة الأصلية والمعتمدة بدل الويب من ناحية الفيتشرز والـ UI وتجربة المستخدم

اهم محاور التطوير المطلوبة بالترتيب:

اولا تحليل الويب: ادخل على مشروع الويب Houseiana-Holidays-Homes-main-web ودور على كل الصفحات والسكاشن والمكونات الرئيسية زى الهيدر والفوتر والنيفيجيشن والقوائم الجانبية وكل الـ components والـ screens اللي بتظهر للمستخدم

ثانيا تحليل الموبايل: روح على مجلد lib/features في مشروع الموبايل وشوف كل الـ features الموجودين وهل فيهم الناقص او محتاج يتعدل او يحتاج يتembangkan

ثالثا مقارنة شاملة: قارن كل قسم في الويب مع القسم المقابل في الموبايل وعمل جدول يوضح: القسم في الويب وصفه في الويب القسم المقابل في الموبايل حاله الحالي تقييم if ناقص ودرجة اولويته من 1 ل 5

رابعا ترتيب الاولويات: رتب التحسينات والتطويرات بناء على: ايه الاكثر اهمية للمستخدم ايه اللي له تأثير كبير على تجربة المستخدم ايه اللي سهل ينفذ وانيفكت كبير

خامسا نقل تجربة المستخدم: ركز جدا على ان تجربة المستخدم في الموبايل تكون مماثلة للويب في كل قسم من حيث: ترتيب العناصر والشاشات طريقة التنقل والتصفح التفاعلات والحركات الانيميشن الـ flow اللي بيتبعه المستخدم

سادسا تحديث الـ UI: اعمل خطة مفصلة لكل قسم في الموبايل فيها: وصف التصميم الحالي في الويب اللي لازم ينقل الوصف التصميم الحالي في الموبايل التعديلات المطلوبة والـ widgets اللي تحتاج تنشأ او تعدل الـ color scheme والـ typography والـ spacing

سابعا تحديث الـ Features: حدد كل feature ناقصة في الموبايل موجوده في الويب وعملها فيفاكر مع وصف تفصيلي ليها

ثامنا ملخص الـ API endpoints: اجمع كل الـ API endpoints اللي المشروعين بيستخدموها والتأكد من ان الموبايل بيستدعي كل ال endpoints المطلوبة

التاچر المطلوب في ملف md واحد شامل اسمحه plans/comprehensive-development-plan.md ويفضل يكون بالترتيب ده:

1. ملخص تنفيذي للمشروعين
2. تحليل هيكل مشروع الويب مع ذكر كل الـ pages والـ components الاساسية
3. تحليل هيكل مشروع الموبايل مع ذكر كل الـ features الموجودة
4. جدول مقارنة شامل بين الويب والموبايل لكل قسم
5. خطة نقل تجربة المستخدم من الويب للموبايل
6. خطة تطوير الـ UI لكل قسم بالتفصيل
7. قائمة الـ features الناقصة في الموبايل المطلوبة من الويب
8. جدول اولويات التنفيذ مع كل feature عليها تقييم
9. قائمة الـ API endpoints المطلوبة
10. الجدول الزمني المتوقع للتنفيذ
11. توصيات وتقترحات اضافية


 وبلمظهر الاحترافي والتنسيق الواضح وكمان اكتب البرومبت اللي استخدمته في اول الملف مع كل التفاصيل والتفضيلات اللي طلبتها

اهم نقطة: لازم كل قسم في الموبايل يطابق القسم المقابل في الويب من حيث الشكل والتركيب وتجربة المستخدم وكل حاجة وكل ما تعمل مقارنة حطلك صورة او وصف للـ layout في الويب وللـ layout في الموبايل ووضح الفرق والتعديلات المطلوبة بالضبط
```

---

## 1. ملخص تنفيذي للمشروعين

### المشروع الأول: Houseiana Web (Next.js)
- **الموقع**: https://houseiana.com
- **التقنية**: Next.js 14 + TypeScript + Tailwind CSS
- **التوجيه**: App Router
- **التوثيق**: Clerk Authentication
- **الخادم**: Railway + Vercel
- **الحالة**: التطبيق الرئيسي المعتمد

### المشروع الثاني: Houseiana Mobile (Flutter)
- **الموقع**: تطبيق موبايل
- **التقنية**: Flutter + Dart
- **التوجيه**: GoRouter
- **التوثيق**: Clerk Authentication (عبر API)
- **الخادم**: نفس API الويب
- **الحالة**: يحتاج تطوير شامل ليطابق الويب

### الهدف الرئيسي
تحويل تطبيق الموبايل ليكون النسخة المعتمدة بدل الويب من حيث:
- الفيتشرز والميزات
- واجهة المستخدم (UI)
- تجربة المستخدم (UX)
- تجربة التنقل والتفاعل

---

## 2. تحليل هيكل مشروع الويب

### 2.1 الصفحات الرئيسية (Main Pages)

| المسار | الوصف | المكونات الرئيسية |
|--------|-------|-------------------|
| `/` | الصفحة الرئيسية | Hero Section, Search Bar, Property Grid, Category Tabs, Trending Destinations |
| `/discover` | صفحة اكتشاف العقارات | Filters, Property Listings, Map View Toggle |
| `/explore` | صفحة استكشاف متقدمة | Grid/Map View, Advanced Filters, Property Cards |
| `/property/[id]` | تفاصيل العقار | Image Gallery, Booking Card, Description, Amenities, Reviews, Host Info |
| `/my-trips` | رحلاتي | Trip Cards, Timeline View, Map View, Calendar View |
| `/client-dashboard` | لوحة تحكم العميل | Trips, Wishlists, Messages, Account Settings |
| `/host-dashboard` | لوحة تحكم المضيف | Overview, Reservations, Listings, Calendar, Earnings |
| `/host-dashboard/add-listing` | إضافة عقار جديد | Multi-step form (14 خطوة) |
| `/host-dashboard/calendar` | تقويم المضيف | Calendar Grid, Pricing Overlay, Reservation Details |
| `/host-dashboard/earnings` | الأرباح | Earnings Chart, Payout History |
| `/host-dashboard/listings` | عقاراتي | Listing Cards, Status Badges |
| `/host-dashboard/reviews` | التقييمات | Review List, Response Form |
| `/account/*` | إعدادات الحساب | Profile, KYC, Payments, Privacy, Security, Preferences |
| `/messages/[id]` | المحادثات | Chat Window, Message Bubbles |
| `/about` | من نحن | Company Info, Team |
| `/contact` | تواصل معنا | Contact Form, Map |
| `/help/*` | مركز المساعدة | FAQ, Articles |
| `/wishlists` | القائمة المفضلة | Wishlist Grid |

### 2.2 المكونات الرئيسية (Components)

#### Header & Navigation
- **HomeHeader**: شريط البحث الرئيسي مع فلاتر
- **Navigation**: قائمة التنقل الرئيسية
- **MobileMenu**: قائمة الموبايل المنسدلة
- **UserMenu**: قائمة المستخدم

#### Property Components
- **PropertyCard**: بطاقة العقار في القائمة
- **PropertyGrid**: شبكة البطاقات
- **ImageGallery**: معرض الصور
- **BookingCard**: بطاقة الحجز
- **PropertyHighlights**: أبرز مميزات العقار
- **AmenitiesSection**: قسم المرافق
- **LocationSection**: قسم الموقع
- **PropertyReviews**: تقييمات العقار

#### Dashboard Components
- **ClientSidebar**: الشريط الجانبي للعميل
- **HostSidebar**: الشريط الجانبي للمضيف
- **TripCard**: بطاقة الرحلة
- **ReservationCard**: بطاقة الحجز للمضيف
- **EarningsChart**: chart الأرباح

#### Chat Components
- **ChatWindow**: نافذة المحادثة
- **ChatList**: قائمة المحادثات
- **MessageBubble**: فقاعة الرسالة
- **MessageInput**: إدخال الرسالة

#### Auth Components
- **SignIn/SignUp**: تسجيل الدخول/التسجيل عبر Clerk
- **ProfileHeader**: رأس الملف الشخصي
- **ProfileStats**: إحصائيات الملف الشخصي
- **ProfileReviews**: تقييمات الملف الشخصي

### 2.3 الـ Features في الويب

| الفئة | الفيتشرز |
|-------|----------|
| **Authentication** | تسجيل الدخول، التسجيل، OTP،نسيت كلمة المرور، إعادة تعيين كلمة المرور |
| **Property Search** | بحث متقدم، فلاتر، خريطة، بحث بالكلمات |
| **Booking** | حجز، تأكيد، إلغاء، استرداد |
| **Payments** | PayPal, Stripe, Sadad, بطاقات الائتمان |
| **User Dashboard** | رحلاتي، المفضلة، الرسائل، الإعدادات |
| **Host Dashboard** | نظرة عامة، حجوزات، تقويم، أرباح، إدراة العقارات |
| **Add Listing** | نموذج 14 خطوة لإضافة عقار جديد |
| **Reviews** | تقييم العقار، الرد على التقييمات |
| **Chat** | محادثات مع المضيفين |
| **Notifications** | إشعارات البريد والإعدادات |
| **KYC** | التحقق من الهوية |
| **Wishlists** | قوائم المفضلة |

---

## 3. تحليل هيكل مشروع الموبايل

### 3.1 الـ Features الموجودة حالياً

```
lib/features/
├── auth/                    # المصادقة
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── sign_up_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   ├── otp_verification_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   └── cubit/
│   ├── auth_cubit.dart
│   └── auth_state.dart
│
├── booking/                # الحجز
│   └── presentation/screens/
│       ├── booking_confirmation_screen.dart
│       ├── booking_request_screen.dart
│       ├── date_selection_screen.dart
│       ├── guest_selection_screen.dart
│       ├── payment_screen.dart
│       ├── payment_method_screen.dart
│       ├── payment_pending_screen.dart
│       ├── payment_failed_screen.dart
│       ├── payment_cancel_screen.dart
│       └── booking_confirmation_screen.dart
│
├── bottom_nav/              # شريط التنقل السفلي
│   └── presentation/screen/
│       └── bottom_nav.dart
│
├── chat/                   # المحادثات
│   ├── data/model/
│   │   ├── chat_model.dart
│   │   └── message_model.dart
│   └── presentation/screens/
│       └── chat_screen.dart
│
├── country/                 # الدول والمدن
│   └── presentation/screens/
│       ├── country_screen.dart
│       └── city_list_screen.dart
│
├── dashboard/              # لوحة التحكم
│   └── presentation/screens/
│       └── client_dashboard_screen.dart
│
├── discover/               # اكتشاف العقارات
│   └── presentation/screens/
│       └── discover_screen.dart
│
├── favorites/             # المفضلة
│   ├── presentation/cubit/
│   │   ├── favorites_cubit.dart
│   │   └── favorites_state.dart
│   └── presentation/screens/
│       ├── favorites_screen.dart
│       └── wishlists_screen.dart
│
├── home/                  # الصفحة الرئيسية
│   └── presentation/screens/
│       └── home_screen.dart
│
├── host/                  # المضيف
│   └── presentation/screens/
│       ├── host_dashboard_screen.dart
│       ├── become_host_screen.dart
│       ├── list_property_screen.dart
│       ├── property_setup_screen.dart
│       ├── pricing_setup_screen.dart
│       └── availability_calendar_screen.dart
│
├── legal/                 # الصفحات القانونية
│   └── presentation/screens/
│       ├── privacy_policy_screen.dart
│       ├── terms_screen.dart
│       └── cookie_policy_screen.dart
│
├── messages/             # الرسائل
│   └── presentation/screens/
│       ├── conversations_screen.dart
│       ├── chat_conversation_screen.dart
│       └── contact_host_screen.dart
│
├── notifications/        # الإشعارات
│   └── presentation/screens/
│       └── notifications_screen.dart
│
├── profile/              # الملف الشخصي
│   ├── presentation/cubit/
│   │   ├── profile_cubit.dart
│   │   └── profile_state.dart
│   └── presentation/screens/
│       ├── profile_screen.dart
│       ├── edit_profile_screen.dart
│       ├── personal_information_screen.dart
│       ├── payment_methods_screen.dart
│       ├── saved_addresses_screen.dart
│       ├── kyc_verification_screen.dart
│       ├── account_settings_screen.dart
│       ├── notification_settings_screen.dart
│       ├── privacy_settings_screen.dart
│       ├── currency_settings_screen.dart
│       ├── language_settings_screen.dart
│       └── change_password_screen.dart
│
├── properties/           # العقارات
│   ├── presentation/cubit/
│   │   ├── properties_cubit.dart
│   │   └── properties_state.dart
│   └── presentation/screens/
│       ├── properties_screen.dart
│       └── search_properties_screen.dart
│
├── property_details/     # تفاصيل العقار
│   ├── presentation/cubit/
│   │   ├── property_details_cubit.dart
│   │   └── property_details_state.dart
│   └── presentation/screens/
│       ├── property_details_screen.dart
│       ├── photo_gallery_screen.dart
│       ├── amenities_screen.dart
│       ├── location_map_screen.dart
│       ├── reviews_screen.dart
│       └── host_profile_screen.dart
│
├── recommendations/      # التوصيات
│   └── presentation/screens/
│       └── recommendations_screen.dart
│
├── search/               # البحث
│   └── presentation/screens/
│       ├── search_modal_screen.dart
│       ├── location_search_screen.dart
│       ├── advanced_filters_screen.dart
│       ├── price_range_filter_screen.dart
│       └── map_full_screen.dart
│
├── splash/               # شاشة البداية
│   └── presentation/screens/
│       └── splash_screen.dart
│
├── support/              # الدعم
│   └── presentation/screens/
│       ├── help_center_screen.dart
│       └── contact_support_screen.dart
│
└── trips/                # الرحلات
    └── presentation/screens/
        ├── trips_screen.dart
        └── trip_details_screen.dart
```

### 3.2 تقييم الحالة الحالية للموبايل

| الفئة | الحالة | الملاحظات |
|-------|--------|----------|
| Auth | ✅ موجود | تسجيل دخول/التسجيل/OTP/نسيت كلمة المرور |
| Home | ⚠️ جزئي | يحتاج تحديث ليتطابق مع الويب |
| Discover | ⚠️ جزئي | فلاتر محدودة |
| Property Details | ⚠️ جزئي | يحتاج إضافة مكونات كثيرة |
| Booking | ✅ جيد | لكن يحتاج تحسينات |
| Dashboard | ⚠️ جزئي | العميل موجود، المضيف محدود |
| Host Dashboard | ❌ ناقص | غير موجود بشكل كامل |
| Add Listing | ❌ ناقص | غير موجود |
| Calendar (Host) | ❌ ناقص | غير موجود |
| Chat | ⚠️ جزئي | يحتاج تحسينات |
| Profile | ⚠️ جزئي | يحتاج إضافة أقسام |
| Search | ⚠️ جزئي | يحتاج تحديثات |

---

## 4. جدول مقارنة شامل بين الويب والموبايل

### 4.1 الصفحات الرئيسية

| القسم في الويب | الوصف في الويب | القسم في الموبايل | الحالة الحالية | التقييم | الأولوية |
|----------------|---------------|------------------|---------------|---------|----------|
| **الصفحة الرئيسية** | HeroSection مع search bar كبير، category tabs، trending destinations، testimonials | `home_screen.dart` | جزئي - يفتقد muchos componentes | 3/5 | عالية |
| **Discover** | Filters sidebar، property grid، quick filters | `discover_screen.dart` | جزئي - فلاتر محدودة | 2/5 | متوسطة |
| **Explore** | Map/Grid toggle، advanced filters، property cards | `search_properties_screen.dart` | جزئي | 2/5 | متوسطة |
| **Property Details** | Image gallery، booking card، description، amenities، location map، reviews، host info | `property_details_screen.dart` | جزئي - يفتقد components كثيرة | 2/5 | عالية جداً |
| **My Trips** | List/timeline/map/calendar views، trip cards، insights | `trips_screen.dart` | جزئي | 3/5 | عالية |
| **Client Dashboard** | Sidebar navigation، trips/wishlists/messages/account tabs | `client_dashboard_screen.dart` | جزئي | 2/5 | متوسطة |
| **Host Dashboard** | Overview، reservations، listings، calendar، earnings | `host_dashboard_screen.dart` |起步 فقط | 1/5 | عالية جداً |
| **Add Listing** | 14-step wizard form | غير موجود | ❌ غير موجود | 0/5 | عالية جداً |
| **Host Calendar** | Calendar grid، pricing overlay، block dates | `availability_calendar_screen.dart` |起步 فقط | 1/5 | عالية جداً |
| **Earnings** | Chart، payout history | غير موجود | ❌ غير موجود | 0/5 | عالية |
| **Messages** | Chat list، conversation view | `conversations_screen.dart` | جزئي | 2/5 | متوسطة |
| **Account Settings** | Profile, KYC, Payments, Privacy, Security | `profile_screen.dart` + several screens | جزئي | 3/5 | متوسطة |
| **Wishlists** | Wishlist grid، share functionality | `wishlists_screen.dart` | موجود | 4/5 | منخفضة |

### 4.2 المكونات (Components)

| المكون في الويب | الوصف | المكون في الموبايل | الحالة | الأولوية |
|----------------|-------|-------------------|--------|----------|
| **PropertyCard** | بطاقة العقار مع صورة وسعر وتقييم | `PropertyCard` in `property_details` | موجود | 3/5 |
| **ImageGallery** | معرض صور مع lightbox | `photo_gallery_screen.dart` | موجود جزئياً | 3/5 |
| **BookingCard** | بطاقة الحجز مع تفاصيل السعر | `payment_screen.dart` | موجود جزئياً | 3/5 |
| **PropertyHighlights** | أبرز المميزات | غير موجود | ❌ | 4/5 |
| **AmenitiesSection** | قسم المرافق | `amenities_screen.dart` | موجود | 3/5 |
| **LocationSection** | الموقع على الخريطة | `location_map_screen.dart` | موجود | 3/5 |
| **PropertyReviews** | التقييمات | `reviews_screen.dart` | موجود | 3/5 |
| **HostInfo** | معلومات المضيف | `host_profile_screen.dart` | موجود | 3/5 |
| **TripCard** | بطاقة الرحلة | `trips_screen.dart` | موجود جزئياً | 3/5 |
| **ReservationCard** | بطاقة الحجز للمضيف | غير موجود | ❌ | 5/5 |
| **EarningsChart** | chart الأرباح | غير موجود | ❌ | 4/5 |
| **ChatWindow** | نافذة المحادثة | `chat_conversation_screen.dart` | موجود جزئياً | 3/5 |
| **SearchBar** | شريط البحث | `search_modal_screen.dart` | موجود | 3/5 |
| **Filters** | فلاتر البحث | `advanced_filters_screen.dart` | موجود جزئياً | 3/5 |
| **MobileBottomNav** | شريط التنقل السفلي | `bottom_nav.dart` | موجود | 4/5 |
| **ClientSidebar** | الشريط الجانبي | غير موجود | ❌ | 3/5 |
| **HostSidebar** | الشريط الجانبي للمضيف | غير موجود | ❌ | 5/5 |

### 4.3 Layout Comparison

#### Homepage Web Layout
```
┌─────────────────────────────────────────────────────────┐
│  Logo    Search Bar (Where, When, Who)      User Menu   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         HERO SECTION (Full Width)                │   │
│  │         Background Image + Overlay Text          │   │
│  │         Large Search Bar in Center               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  [Categories: All, Houses, Apartments, Villas, etc.]     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Property Grid (3-4 columns)                     │   │
│  │  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐       │   │
│  │  │ Card  │ │ Card  │ │ Card  │ │ Card  │       │   │
│  │  └───────┘ └───────┘ └───────┘ └───────┘       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Trending Destinations Section                   │   │
│  │  [City Cards in Horizontal Scroll]               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Homepage Mobile Layout (Current)
```
┌───────────────────────┐
│ ☰    Logo      🔔  👤 │
├───────────────────────┤
│  ┌─────────────────┐  │
│  │  Search Bar     │  │
│  │  [Where?    ▼]  │  │
│  │  [Check in  ▼]  │  │
│  │  [Check out ▼]  │  │
│  │  [Guests    ▼]  │  │
│  └─────────────────┘  │
│                       │
│  [Categories Tabs]    │
│                       │
│  ┌─────────────────┐  │
│  │ Property Card   │  │
│  ├─────────────────┤  │
│  │ Property Card   │  │
│  ├─────────────────┤  │
│  │ Property Card   │  │
│  └─────────────────┘  │
│                       │
│        🔴 🟢 🟡 🔵    │
└───────────────────────┘
```

#### المطلوب تحديثه في Homepage Mobile
1. إضافة Hero Section مع خلفية صورة
2. تحسين شريط البحث ليكون أكبر وأكثر وضوحاً
3. إضافة trending destinations section
4. تحسين grid layout للبطاقات

---

## 5. خطة نقل تجربة المستخدم من الويب للموبايل

### 5.1 принципы переноса UX

1. **التناظر (Parity)**: كل عنصر في الويب يجب أن يكون له مقابل في الموبايل
2. **السياق (Context)**: مراعاة أن المستخدم يتفاعل باللمس وليس الماوس
3. **البساطة (Simplicity)**: تبسيط التنقل دون فقدان الوظائف
4. **الاستمرارية (Consistency)**: نفس لغة التصميم والتنظيم

### 5.2 Navigation Flow

#### Web Navigation Flow
```
Home → Search/Discover → Property Details → Booking Flow → Confirmation
         ↓                    ↓
      Filters            Reviews & FAQ
         ↓                    ↓
      Map View           Host Profile
```

#### Mobile Navigation Flow (المطلوب)
```
Bottom Nav:
├── Home (الصفحة الرئيسية)
├── Search (البحث والاستكشاف)
├── Trips (رحلاتي)
├── Messages (الرسائل)
└── Profile (الحساب)

In-page Navigation:
├── Scroll & Tap for content
├── Swipe for image gallery
├── Pull-to-refresh for lists
├── Bottom sheets for filters
└── Modal screens for actions
```

### 5.3 Animation & Interactions

| Interaction | Web Behavior | Mobile Behavior |
|-------------|--------------|-----------------|
| Hover on cards | Scale up + shadow | Tap to select |
| Image gallery | Click to open lightbox | Swipe + tap |
| Filters | Sidebar slide-in | Bottom sheet slide-up |
| Loading | Spinner overlay | Skeleton screens |
| Error | Toast notification | Snack bar |
| Success | Modal + redirect | Bottom notification |

### 5.4 User Flow Mapping

#### Booking Flow (Web)
```
Property Details → Select Dates → Select Guests → Review Price → Payment → Confirmation
                      ↓                ↓              ↓            ↓
                  Calendar Picker   Counter       Price Summary   Success Page
```

#### Booking Flow (Mobile - المطلوب)
```
Property Details Screen
    ↓ [tap "Reserve"]
Date Selection Screen (Full-screen calendar)
    ↓ [select dates]
Guest Selection Screen
    ↓ [tap "Continue"]
Payment Screen
    ↓ [complete payment]
Booking Confirmation Screen
```

### 5.5 Gesture-based Interactions

| Gesture | Action |
|---------|--------|
| Swipe left/right | Image gallery navigation |
| Swipe down | Close bottom sheet / go back |
| Long press | Show context menu |
| Pull down | Refresh content |
| Pinch | Zoom on map/images |
| Double tap | Zoom on property images |

---

## 6. خطة تطوير الـ UI لكل قسم بالتفصيل

### 6.1 Homepage (الصفحة الرئيسية)

#### التصميم الحالي في الويب
- Hero section يغطي 70% من الشاشة
- Search bar كبير في وسط الـ hero
- Category tabs أسفل الـ hero
- Property grid في 4 أعمدة
- Trending destinations في horizontal scroll

#### التصميم الحالي في الموبايل
- Header بسيط مع أيقونات
- Search bar صغير في الأعلى
- Category tabs في صف واحد
- Property cards في عمود واحد

#### التعديلات المطلوبة
1. إضافة Hero section مع صورة خلفية
2. تكبير شريط البحث وجعله في مركز الـ hero
3. إضافة overlay gradient لتحسين قراءة النص
4. إضافة animated search bar expansion
5. تحسين Property cards layout (2 في الصف)
6. إضافة Trending Destinations section
7. إضافة Trust & Safety section
8. إضافة Testimonials section

#### Color Scheme المطلوب
```dart
Primary: #00AEEF (Houseiana Blue)
Secondary: #1A1A2E (Dark Navy)
Accent: #FF6B6B (Coral)
Background: #FFFFFF
Surface: #F5F7FA
Text Primary: #1A1A2E
Text Secondary: #6B7280
Success: #10B981
Error: #EF4444
Warning: #F59E0B
```

#### Typography المطلوب
```dart
Headings: Inter Bold
  - H1: 32sp
  - H2: 24sp
  - H3: 20sp
  - H4: 16sp

Body: Inter Regular
  - Body1: 16sp
  - Body2: 14sp
  - Caption: 12sp

Font Weights:
  - Regular: 400
  - Medium: 500
  - SemiBold: 600
  - Bold: 700
```

### 6.2 Property Details Screen

#### التصميم الحالي في الويب
- Full-width image gallery في الأعلى
- Property info في عمود يسار
- Booking card ثابت في يمين الشاشة
- Tabs للأقسام (Description, Amenities, Reviews, etc.)
- Sticky booking card عند التمرير

#### التصميم الحالي في الموبايل
- Image carousel في الأعلى
- Property info يليه
- Booking button في الأسفل (sticky)
- Tab bar للأقسام

#### التعديلات المطلوبة
1. إضافة expandable image gallery
2. إضافة Property highlights component
3. إضافة Meet Your Host section
4. إضافة Things to Know section
5. تحسين booking card layout
6. إضافة share button
7. إضافة favorite heart button
8. تحسين reviews display

#### Widgets الجديدة المطلوبة
```dart
// جديد
PropertyHighlightsWidget()
MeetYourHostWidget()
ThingsToKnowWidget()
BookingCardWidget() // مُحدث
ImageGalleryLightbox() // مُحدث
ShareButtonWidget()
RatingBreakdownWidget()
```

### 6.3 Host Dashboard

#### التصميم الحالي في الويب
- Sidebar navigation يسار الشاشة
- Dashboard overview في أعلى الصفحة
- Stats cards (earnings, bookings, etc.)
- Recent reservations list
- Quick actions buttons

#### التصميم الحالي في الموبايل
- Basic dashboard مع إحصائيات
- Limited navigation

#### التعديلات المطلوبة
1. إضافة drawer navigation للمضيف
2. إضافة Overview section with stats
3. إضافة upcoming reservations section
4. إضافة quick actions (add listing, view calendar)
5. إضافة performance metrics
6. إضافة earnings chart widget

#### Widgets الجديدة المطلوبة
```dart
HostDashboardDrawer()
StatsOverviewWidget()
UpcomingReservationsWidget()
QuickActionsWidget()
PerformanceChartWidget()
Host Earnings Widget()
```

### 6.4 Add Listing Flow

#### في الويب
- 14-step wizard مع progress indicator
- كل خطوة في صفحة منفصلة
- Save draft تلقائي
- Preview قبل النشر

#### في الموبايل (غير موجود)

#### المطلوب إنشاؤه
```dart
AddListingWizard()
  ├── StepIndicator()
  ├── PropertyTypeStep()
  ├── LocationStep()
  ├── BasicsStep() // bedrooms, beds, bathrooms
  ├── AmenitiesStep()
  ├── PhotosStep()
  ├── TitleStep()
  ├── DescriptionStep()
  ├── PricingStep()
  ├── DiscountsStep()
  ├── LegalStep()
  ├── HouseRulesStep()
  ├── CancellationPolicyStep()
  └── ReviewStep()
```

#### UI Specifications
- Progress indicator في الأعلى
- Navigation buttons (Back, Next) في الأسفل
- Auto-save مع last saved indicator
- Image picker مع drag & drop
- Map integration للـ location

### 6.5 Calendar Screen (Host)

#### في الويب
- Monthly calendar grid
- Color coding للحالات (available, booked, blocked)
- Click to select date range
- Pricing overlay على التواريخ
- Side panel للتفاصيل

#### في الموبايل
- Basic calendar display

#### التعديلات المطلوبة
1. إضافة legend للـ color coding
2. إضافة date range selection
3. إضافة pricing mode toggle
4. إضافة reservation details bottom sheet
5. إضافة block dates functionality
6. إضافة min nights settings

### 6.6 Search & Filters

#### في الويب
- Sidebar filters
- Map view toggle
- Grid/List view toggle
- Advanced filters (price, amenities, etc.)

#### في الموبايل
- Basic filters
- Limited UI

#### التعديلات المطلوبة
1. Bottom sheet filters
2. Map view (full screen)
3. Save search functionality
4. Clear all filters button
5. Filter chips display
6. Sort options dropdown

---

## 7. قائمة الـ Features الناقصة في الموبايل المطلوبة من الويب

### 7.1 High Priority Features

#### 1. Host Dashboard المتقدم
- **الوصف**: لوحة تحكم كاملة للمضيف مع كل الوظائف
- **الفايفاكر**:
```
HostDashboardScreen
├── Overview Tab
│   ├── StatsCards (Total Earnings, Bookings, Rating)
│   ├── Recent Activity
│   └── Quick Actions
├── Reservations Tab
│   ├── ReservationList
│   ├── Filter by Status
│   └── Reservation Details Sheet
├── Calendar Tab
│   ├── Monthly View
│   ├── Pricing Overlay
│   └── Block Dates
├── Listings Tab
│   ├── PropertyList
│   ├── Add New Property
│   └── Edit Property
├── Earnings Tab
│   ├── Earnings Chart
│   ├── Payout Schedule
│   └── Transaction History
└── Reviews Tab
    ├── ReviewList
    └── Response Form
```
- **الأولوية**: 5/5

#### 2. Add Listing Wizard
- **الوصف**: نموذج إضافة عقار جديد بـ 14 خطوة
- **الفايفاكر**:
```
AddListingFlow
├── Intro Screen
├── Step 1: Property Type Selection
├── Step 2: Location (Map + Address Form)
├── Step 3: Basics (Guests, Bedrooms, Beds, Bathrooms)
├── Step 4: Amenities Selection
├── Step 5: Photos Upload (Multiple with reorder)
├── Step 6: Title
├── Step 7: Description
├── Step 8: Pricing Setup
├── Step 9: Discounts (Weekly, Monthly, Custom)
├── Step 10: Legal Documents
├── Step 11: House Rules
├── Step 12: Cancellation Policy
├── Step 13: Review & Preview
└── Step 14: Confirmation
```
- **الأولوية**: 5/5

#### 3. Host Calendar المتقدم
- **الوصف**: تقويم كامل مع إدارة الأسعار والتواريخ
- **الفايفاكر**:
```
HostCalendarScreen
├── Month Navigation Header
├── Calendar Grid
│   ├── Color coded cells (Available, Booked, Blocked)
│   ├── Price labels
│   └── Click interaction
├── Legend (Color meanings)
├── Selected Date Actions
│   ├── View Reservation
│   ├── Block Date
│   └── Update Price
├── Pricing Mode Toggle
├── Block Reason Selection
└── Min Nights Configuration
```
- **الأولوية**: 5/5

#### 4. Property Highlights Component
- **الوصف**: عرض أبرز مميزات العقار
- **الفايفاكر**:
```
PropertyHighlightsCard
├── Icon + Label pairs
├── Highlight items:
│   ├── Host's property type expertise
│   ├── Quick response badge
│   ├── Superhost status
│   ├── Recent booking count
│   └── Favorite count
└── Tap to expand details
```
- **الأولوية**: 4/5

#### 5. Meet Your Host Section
- **الوصف**: معلومات عن المضيف
- **الفايفاكر**:
```
MeetYourHostCard
├── Host Photo
├── Host Name
├── Host Since Date
├── Superhost Badge
├── Response Rate & Time
├── About Section
└── View Profile Button
```
- **الأولوية**: 4/5

#### 6. Things to Know Section
- **الوصف**: قواعد ومعلومات عن العقار
- **الفايفاكر**:
```
ThingsToKnowSection
├── House Rules Tab
├── Safety Items Tab
└── Cancellation Policy Tab
```
- **الأولوية**: 4/5

### 7.2 Medium Priority Features

#### 7. Client Dashboard المتقدم
- **الوصف**: تحسين لوحة تحكم العميل
- **الفايفاكر**:
```
ClientDashboardScreen
├── Trips Tab (مُحدث)
├── Wishlists Tab
├── Messages Tab
└── Account Tab
    ├── Profile Section
    ├── Payment Methods
    ├── Notification Preferences
    └── Privacy Settings
```
- **الأولوية**: 3/5

#### 8. Reservations List (Host)
- **الوصف**: قائمة الحجوزات للمضيف
- **الفايفاكر**:
```
ReservationsListView
├── Filter Tabs (Upcoming, Past, Cancelled)
├── Reservation Cards
│   ├── Guest Info
│   ├── Property Info
│   ├── Dates
│   ├── Amount
│   └── Status Badge
├── Pull to Refresh
└── Load More Pagination
```
- **الأولوية**: 4/5

#### 9. Earnings Dashboard
- **الوصف**: عرض الأرباح للمضيف
- **الفايفاكر**:
```
EarningsScreen
├── Summary Cards
│   ├── This Month
│   ├── This Year
│   └── All Time
├── Earnings Chart (Line/Bar)
├── Payout Schedule
├── Transaction List
└── Export Button
```
- **الأولوية**: 4/5

#### 10. Enhanced Search Experience
- **الوصف**: تحسين تجربة البحث
- **الفايفاكر**:
```
EnhancedSearchScreen
├── Recent Searches
├── Saved Searches
├── Search Suggestions
├── Map View Toggle
├── Grid/List View Toggle
├── Advanced Filters Bottom Sheet
│   ├── Price Range Slider
│   ├── Property Type
│   ├── Bedrooms/Bathrooms
│   ├── Amenities Checkboxes
│   └── More Filters
└── Sort Options
```
- **الأولوية**: 3/5

#### 11. Chat Improvements
- **الوصف**: تحسين نظام المحادثات
- **الفايفاكر**:
```
EnhancedChatScreen
├── Conversation List with unread badges
├── Search Conversations
├── Chat Window
│   ├── Message Bubbles (sent/received)
│   ├── Timestamps
│   ├── Read Receipts
│   └── Quick Replies
├── New Message FAB
└── Online Status Indicators
```
- **الأولوية**: 3/5

### 7.3 Lower Priority Features

#### 12. Profile增强
- **الوصف**: إضافة أقسام للملف الشخصي
- **الفايفاكر**:
```
EnhancedProfileScreen
├── Profile Header
├── Stats (Trips, Reviews, Favorites)
├── verifications Badges
├── Reviews Given/Received
└── Listed Properties (for hosts)
```
- **الأولوية**: 2/5

#### 13. Analytics Dashboard (Host)
- **الوصف**: إحصائيات وتحليلات للمضيف
- **الفايفاكر**:
```
HostAnalyticsScreen
├── Views Chart
├── Bookings Chart
├── Revenue Chart
├── Guest Demographics
├── Popular Dates
└── Comparison with Previous Period
```
- **الأولوية**: 2/5

#### 14. Help Center App-Like Experience
- **الوصف**: مركز مساعدة محسن
- **الفايفاكر**:
```
HelpCenterScreen
├── Search Bar
├── Categories Grid
├── Popular Articles
├── Contact Support Button
└── FAQ Accordion
```
- **الأولوية**: 2/5

---

## 8. جدول اولويات التنفيذ مع تقييم

| Priority | Feature | Impact | Effort | Score |理由 |
|----------|---------|--------|--------|-------|------|
| **P1** | Host Dashboard المتقدم | عالية | عالية | 8 |核心功能 للمضيفين |
| **P1** | Add Listing Wizard | عالية | عالية | 8 | أساسي لإضافة عقارات |
| **P1** | Host Calendar | عالية | متوسطة | 9 | سهل التنفيذ،Impact tinggi |
| **P1** | Property Details التحديث | عالية | متوسطة | 9 | المستخدمون يروه أولاً |
| **P2** | Property Highlights | متوسطة | منخفضة | 8 | سريع التنفيذ |
| **P2** | Meet Your Host | متوسطة | منخفضة | 8 | سريع التنفيذ |
| **P2** | Things to Know | متوسطة | منخفضة | 8 | سريع التنفيذ |
| **P2** | Reservations List | عالية | متوسطة | 7 | مهم للمضيفين |
| **P3** | Earnings Dashboard | متوسطة | متوسطة | 6 | مهم لكن ليس عاجل |
| **P3** | Enhanced Search | عالية | متوسطة | 7 | يحسن UX كثير |
| **P3** | Chat Improvements | متوسطة | متوسطة | 6 | تحسينcommunication |
| **P4** | Profile Enhancements | منخفضة | منخفضة | 5 | ليس core functionality |
| **P4** | Analytics Dashboard | متوسطة | عالية | 4 | معقد وlow priority |
| **P4** | Help Center | منخفضة | متوسطة | 4 | يمكن تأجيله |

---

## 9. قائمة الـ API Endpoints المطلوبة

### 9.1 Authentication & User

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| POST | `/api/auth/signin` | تسجيل الدخول | ✅ موجود |
| POST | `/api/auth/signup` | التسجيل | ✅ موجود |
| POST | `/api/auth/otp/verify` | التحقق من OTP | ✅ موجود |
| POST | `/api/auth/otp/resend` | إعادة إرسال OTP | ✅ موجود |
| POST | `/api/auth/password/reset` | إعادة تعيين كلمة المرور | ✅ موجود |
| GET | `/api/me` | بيانات المستخدم الحالي | ✅ موجود |
| PUT | `/api/account/profile` | تحديث الملف الشخصي | ⚠️ جزئي |

### 9.2 Properties

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/properties` | قائمة العقارات | ✅ موجود |
| GET | `/api/properties/[id]` | تفاصيل العقار | ✅ موجود |
| POST | `/api/properties` | إنشاء عقار جديد | ❌ غير موجود |
| PUT | `/api/properties/[id]` | تحديث العقار | ❌ غير موجود |
| DELETE | `/api/properties/[id]` | حذف العقار | ❌ غير موجود |
| GET | `/api/property-search` | بحث العقارات | ⚠️ جزئي |
| GET | `/api/properties/[id]/availability` | توافر العقار | ⚠️ جزئي |
| GET | `/api/properties/[id]/calendar` | تقويم العقار | ❌ غير موجود |

### 9.3 Bookings

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/bookings` | قائمة الحجوزات | ⚠️ جزئي |
| GET | `/api/bookings/[id]` | تفاصيل الحجز | ⚠️ جزئي |
| POST | `/api/bookings` | إنشاء حجز | ✅ موجود |
| PUT | `/api/bookings/[id]` | تحديث الحجز | ⚠️ جزئي |
| DELETE | `/api/bookings/[id]` | إلغاء الحجز | ⚠️ جزئي |
| POST | `/api/bookings/verify` | تأكيد الحجز | ✅ موجود |
| POST | `/api/bookings/pay-balance` | دفع الباقي | ⚠️ جزئي |

### 9.4 Payments

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| POST | `/api/payment-methods` | إضافة طريقة دفع | ⚠️ جزئي |
| GET | `/api/payment-methods` | قائمة طرق الدفع | ⚠️ جزئي |
| DELETE | `/api/payment-methods/[id]` | حذف طريقة دفع | ⚠️ جزئي |
| POST | `/api/paypal/create-order` | إنشاء طلب PayPal | ⚠️ جزئي |
| POST | `/api/paypal/capture-order` | تأكيد طلب PayPal | ⚠️ جزئي |
| POST | `/api/sadad/initiate` | بدء دفع Sadad | ⚠️ جزئي |
| POST | `/api/sadad/callback` | رد Sadad | ⚠️ جزئي |

### 9.5 Favorites & Wishlists

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/favorites` | قائمة المفضلة | ✅ موجود |
| POST | `/api/favorites` | إضافة للمفضلة | ✅ موجود |
| DELETE | `/api/favorites/[id]` | حذف من المفضلة | ✅ موجود |

### 9.6 Chat & Messaging

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/guest/conversations` | محادثات الضيف | ⚠️ جزئي |
| GET | `/api/host/conversations` | محادثات المضيف | ⚠️ جزئي |
| GET | `/api/messages/[conversationId]` | رسائل المحادثة | ⚠️ جزئي |
| POST | `/api/messages` | إرسال رسالة | ⚠️ جزئي |

### 9.7 Reviews

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/properties/[id]/reviews` | تقييمات العقار | ✅ موجود |
| POST | `/api/properties/[id]/reviews` | إضافة تقييم | ⚠️ جزئي |
| GET | `/api/users/[id]/reviews` | تقييمات المستخدم | ⚠️ جزئي |

### 9.8 Host Features

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/host/listings` | عقارات المضيف | ⚠️ جزئي |
| GET | `/api/host/reservations` | حجوزات المضيف | ❌ غير موجود |
| GET | `/api/earnings` | الأرباح | ❌ غير موجود |
| GET | `/api/host/calendar` | تقويم المضيف | ❌ غير موجود |
| POST | `/api/host/block-dates` | bloquear التواريخ | ❌ غير موجود |
| PUT | `/api/host/pricing` | تحديث الأسعار | ❌ غير موجود |

### 9.9 Lookups & Settings

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| GET | `/api/lookups/countries` | الدول | ✅ موجود |
| GET | `/api/lookups/cities` | المدن | ✅ موجود |
| GET | `/api/lookups/amenities` | المرافق | ✅ موجود |
| GET | `/api/lookups/booking-status` | حالات الحجز | ⚠️ جزئي |
| GET | `/api/account/payments` | سجل المدفوعات | ⚠️ جزئي |
| GET | `/api/account/notifications` | الإشعارات | ⚠️ جزئي |

### 9.10 Upload & Media

| Method | Endpoint | الوصف | الحالة في الموبايل |
|--------|----------|-------|-------------------|
| POST | `/api/upload-photo` | رفع صورة | ⚠️ جزئي |
| POST | `/api/upload-cloudinary` | رفع لـ Cloudinary | ⚠️ جزئي |

---

## 10. الجدول الزمني المتوقع للتنفيذ

### Phase 1: Core Property Features (4 weeks)
```
Week 1-2:
├── Update Property Details Screen
│   ├── Add Property Highlights
│   ├── Add Meet Your Host
│   ├── Add Things to Know
│   └── Improve Image Gallery
└── Update Search/Discover
    ├── Enhanced Filters
    └── Map View Integration

Week 3-4:
├── Host Dashboard Basics
│   ├── Overview Stats
│   ├── Reservations List
│   └── Quick Actions
└── Host Calendar (Basic)
    ├── Calendar View
    └── Date Selection
```

### Phase 2: Host Listing Management (4 weeks)
```
Week 5-6:
├── Add Listing Wizard - Part 1
│   ├── Property Type
│   ├── Location
│   └── Basics
└── Add Listing Wizard - Part 2
    ├── Amenities
    ├── Photos
    └── Title

Week 7-8:
├── Add Listing Wizard - Part 3
│   ├── Description
│   ├── Pricing
│   └── Discounts
└── Add Listing Wizard - Part 4
    ├── Legal
    ├── House Rules
    └── Review & Publish
```

### Phase 3: Payments & Earnings (3 weeks)
```
Week 9:
├── Payment Methods Management
│   ├── Add Card
│   ├── Remove Card
│   └── Set Default
└── Host Earnings Dashboard
    ├── Earnings Chart
    └── Payout History

Week 10-11:
├── Host Calendar Advanced
│   ├── Pricing Updates
│   ├── Block Dates
│   └── Min Nights
└── Host Reservations Management
    ├── Confirm/Decline
    └── Reservation Details
```

### Phase 4: Polish & Optimization (2 weeks)
```
Week 12:
├── Chat Improvements
├── Search Optimization
└── Performance Optimization

Week 13:
├── UI/UX Polish
├── Testing & Bug Fixes
└── Documentation
```

---

## 11. توصيات وتقترحات اضافية

### 11.1 Technical Recommendations

1. **State Management**: الاستمرار في استخدام Bloc مع better organization
2. **Code Generation**: استخدام freezed لـ immutable models
3. **API Layer**: إنشاء dedicated API service classes
4. **Caching**: إضافة local caching للبيانات المتكررة
5. **Error Handling**: unified error handling approach

### 11.2 UX Recommendations

1. **Skeleton Loading**: استخدام skeleton screens بدلاً من spinners
2. **Pull to Refresh**: إضافة لجميع القوائم القابلة للتحديث
3. **Infinite Scroll**: للقوائم الكبيرة بدلاً من pagination
4. **Offline Support**: تخزين البيانات الأساسية للعمل offline
5. **Deep Linking**: دعم الروابط العميقة للتنقل

### 11.3 Performance Recommendations

1. **Image Optimization**: استخدام cached_network_image
2. **Lazy Loading**: تحميل الصور والمكونات عند الحاجة
3. **List Recycling**: إعادة استخدام العناصر في القوائم
4. **Code Splitting**: تحميل الـ features عند الطلب
5. **Memoization**: تجنب إعادة الحسابات

### 11.4 Testing Recommendations

1. **Unit Tests**: للbusiness logic و cubits
2. **Widget Tests**: للـ UI components
3. **Integration Tests**: للـ flows الرئيسية
4. **Golden Tests**: لـ UI consistency

### 11.5 Documentation Recommendations

1. **API Documentation**: توثيق جميع endpoints
2. **Component Library**: إنشاء مستندات للـ widgets
3. **Flow Diagrams**: مخططات سير العمل
4. **Onboarding Guide**: دليل للمستخدمين الجدد

### 11.6 Future Enhancements

1. **Push Notifications**: إشعارات الـ push
2. **Offline Mode**: العمل بدون إنترنت
3. **Multi-language**: دعم لغات متعددة
4. **Dark Mode**: الوضع الداكن
5. **Accessibility**: تحسين إمكانية الوصول

---

## Summary

هذه الخطة الشاملة تتضمن:
- ✅ تحليل كامل لمشروع الويب والموبايل
- ✅ جدول مقارنة مفصل
- ✅ خطة نقل UX
- ✅ خطة تطوير UI مفصلة
- ✅ قائمة features ناقصة مع أولويات
- ✅ قائمة API endpoints المطلوبة
- ✅ جدول زمني للتنفيذ
- ✅ توصيات تقنية وظيفية

**ملاحظة مهمة**: هذه الخطة طويلة المدى ويمكن تنفيذها على مراحل. الأولوية القصوى يجب أن تكون للـ Host Dashboard و Add Listing لأنهما الأساس لعمل منصة Houseiana.