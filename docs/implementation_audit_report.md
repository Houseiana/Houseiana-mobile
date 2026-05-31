# تقرير تدقيق تنفيذ تطبيق Houseiana Mobile

**تاريخ التدقيق:** 2026-04-24  
**المُدقق:** Kilo (Audit Agent)  
**منهجية التدقيق:** فحص كود ثابت (Static Code Analysis) + محاولة بناء فعلية + تتبع مسارات التنقل + تحليل Dependency Injection  
**نطاق التدقيق:** Flutter codebase بالكامل (`lib/`)

---

## 1. ملخص تنفيذي

التطبيق يحتوي على بنية هيكلية واسعة (~75% من الملفات موجودة)، لكن الفجوة بين "الوجود في الكود" و"العمل بشكل صحيح" كبيرة جدًا. الكثير من الميزات موجودة على الورق لكنها إما:
- غير قابلة للبناء (missing dependencies, SDK mismatch)
- غير موصلة بالتطبيق (dead routes, placeholder wrappers)
- أو تحتوي على أكواد وهمية (stub buttons, fake dialogs, TODO comments)

التأثير المرئي الفعلي للمستخدم ضعيف (~30%) لأن معظم العمل كان هيكليًا داخليًا (typed models, services) بينما الشاشات المخفية والأزرار الوهمية تُبقي التطبيق يبدو غير مكتمل.

### أهم العوائق الحرجة (Critical Blockers)

1. **التطبيق لا يبني أساسًا** — Dart SDK المطلوب `^3.6.0` لكن البيئة الحالية `3.2.0`. `flutter pub get` يفشل.
2. **`webview_flutter` مفقود من `pubspec.yaml`** — شاشات SADAD و PayPal تستوردها لكنها غير مُدرجة، لذا تدفق الدفع مكسور بالكامل.
3. **لا يوجد `Authorization: Bearer` header في أي طلب API** — `AuthInterceptor` يطبع فقط (`debugPrint`) ولا يضيف التوكن. جميع طلبات API بعد تسجيل الدخول تُرسل بدون مصادقة.
4. **crash فوري في شاشة الإشعارات** — `NotificationsCubit` تستخدم `_userSession.id` (غير موجود) بدلًا من `_userSession.userId`.
5. **`PropertyWizardScreen` placeholder** — الـ 13 خطوة موجودة كملفات لكن الشاشة الرئيسية هي مجرد `Text('Property Wizard')` ولا يوجد router يؤدي إليها.
6. **`HostBookingsCubit.acceptBooking` تستدعي endpoint خاطئ** — تستدعي `updateListing(bookingId, ...)` بدلًا من endpoint خاص بالحجوزات.
7. **وحدات Dependency Injection غير مُهيأة** — `initHost()`, `initNotifications()`, `initProfile()` معرّفة لكن **لا تُستدعى أبدًا** في `injection_container.dart`، مما يعني أن الـ Cubits التالية ستُسبب crash عند فتح شاشاتها:
   - `HostBookingsCubit`, `ListingWizardCubit`
   - `NotificationsCubit`
   - `KycCubit`, `SavedAddressesCubit`, `PaymentMethodsCubit`

---

## 2. صحة البناء والتجميع (Build & Compilation Health)

### 🔴 blocker حرج: عدم توافق Dart SDK
- **الملف:** `pubspec.yaml` (السطر 8)
- **المشكلة:** `sdk: ^3.6.0` لكن البيئة الحالية `Dart 3.2.0` / `Flutter 3.16.0`
- **التأثير:** `flutter pub get` يفشل بالكامل. التطبيق لا يبني أساسًا.
```
The current Dart SDK version is 3.2.0.
Because houseiana_mobile_app requires SDK version ^3.6.0, version solving failed.
```

### 🔴 blocker حرج: `webview_flutter` مفقود من `pubspec.yaml`
- **الملفات المتأثرة:**
  - `lib/features/booking/presentation/screens/sadad_webview_screen.dart` (السطر 2)
  - `lib/features/booking/presentation/screens/paypal_webview_screen.dart` (السطر 2)
- **المشكلة:** تستورد `package:webview_flutter/webview_flutter.dart` لكنها غير مُدرجة في `pubspec.yaml`
- **التأثير:** تدفق الدفع عبر SADAD و PayPal مكسور بالكامل. حتى لو تم إصلاح SDK، سيفشل التجميع بسبب import غير موجود.

### 🟡 تحذير: إصدارات dependencies بدون قيود
- **الملف:** `pubspec.yaml` (الأسطر 56–57, 61, 67)
- `google_sign_in:` بدون إصدار
- `sign_in_with_apple:` بدون إصدار
- `paypal_checkout:` بدون إصدار
- `firebase_auth:` بدون إصدار
- **التأثير:** قد يسبب تعارضات في الإصدارات عند `pub get`.

### 🔴 blocker حرج: error تصريف (compile-time) في `NotificationsCubit`
- **الملف:** `lib/features/notifications/cubit/notifications_cubit.dart` (الأسطر 16, 43)
- **المشكلة:** `_userSession.id` — الخاصية `id` **غير موجودة** في `UserSession`. الصحيح هو `userId`.
- **التأثير:** حتى لو تم حل مشكلة SDK، سيفشل `flutter analyze` أو يتوقف التطبيق عن العمل عند فتح شاشة الإشعارات.

---

## 3. تدقيق الطبقة الأساسية (Foundation Layer)

### 3.1 Typed Models — مكتملة ✅
- **الملفات:** `lib/core/models/` — جميعها موجودة وهيكلية:
  - `booking_model.dart`
  - `property_model.dart`
  - `user_model.dart`
  - `review_model.dart`
  - `trip_model.dart`
  - `payment_result_model.dart`
  - `notification_model.dart`
- **التقييم:** الموديلات مكتوبة بشكل جيد وتستخدم `fromJson`/`toJson`. لكن **لا يتم استخدامها بشكل كامل في بعض الشاشات** التي لا تزال تتعامل مع `Map<String, dynamic>`.

### 3.2 Error Handling in Services — ضعيف ⚠️
- **الملف:** `lib/core/services/chat_service.dart`
- **المشكلة:** جميع الأخطاء مبتلعة (`catch (_) { return []; }` أو `catch (_) { return null; }`)
  - السطور: 33–35, 43–45, 66–68, 85–87, 107–109, 121–123
- **الملف:** `lib/core/services/notification_service.dart`
- **المشكلة:** نفس النمط — `catch (_)` في جميع الطرق (الأسطر 13, 22, 30, 41)
- **الملف:** `lib/core/services/user_service.dart`
- **المشكلة:** بعض الطرق تبتلع الأخطاء (مثل `getFavorites` السطر 37–39، `getAddresses` السطر 133–135، `getPaymentMethods` السطر 162–164) بينما طرق أخرى تتركها تتفاقم (مثل `getUser` بدون `try/catch`).
- **الملف:** `lib/core/services/host_service.dart`
- **التقييم:** ✅ **هذا هو النموذج الصحيح** — يستخدم `try/catch` مع `throw _mapDioException(e)`.

### 3.3 Routes — مسجلة لكن غير متناسقة ⚠️
- **الملف:** `lib/core/constants/routes/routes.dart`
- **التقييم:** جميع الثوابت موجودة (50+ route). ✅
- **الملف:** `lib/core/constants/routes/app_routes.dart`
- **التقييم:** جميع الراوتس مسجلة مع `BlocProvider` حيثما يلزم. ✅
- **لكن:** بعض الشاشات تستخدم **سلاسل نصية硬编码** بدلًا من الثوابت:
  - `lib/features/support/presentation/screens/help_center_screen.dart` (السطر 221): `'/contact-support'` بدل `Routes.contactSupport`
  - `lib/features/booking/presentation/screens/payment_cancel_screen.dart` (الأسطر 170, 190): `'/properties'`، `'/wishlists'`
  - `lib/features/booking/presentation/screens/payment_failed_screen.dart` (الأسطر 174, 194): `'/payment-methods'`، `'/contact-support'`
  - `lib/features/booking/presentation/screens/payment_pending_screen.dart` (السطر 165): `'/contact-support'`
  - `lib/features/dashboard/presentation/screens/client_dashboard_screen.dart` (الأسطر 30, 127, 163, 210–235): تستخدم جميعها سلاسل نصية بدل الثوابت
  - `lib/features/host/presentation/screens/become_host_screen.dart` (السطر 164): `'/list-property'`
  - `lib/features/legal/presentation/screens/privacy_policy_screen.dart` (السطر 172): `'/contact-support'`
  - `lib/features/legal/presentation/screens/terms_screen.dart` (السطر 167): `'/contact-support'`
  - `lib/features/profile/presentation/screens/account_settings_screen.dart` (الأسطر 55, 61, 96, 102, 170): سلاسل نصية
- **التأثير:** إذا تغيرت قيمة الثابت لاحقًا، ستبقى هذه الروابط مكسورة.

---

## 4. تدقيق تدفق الحجز والدفع (Booking & Payment Flow)

### 4.1 Booking Request Screen — يعمل ✅
- **الملف:** `lib/features/booking/presentation/screens/booking_request_screen.dart`
- **التقييم:**
  - ✅ يستدعي `BookingCubit.createBooking()` (السطر 741)
  - ✅ الرسوم (cleaning fee, service fee) تقرأ من بيانات العقار (`_property['fees']`) وليست ثابتة
  - ✅ يمرر `bookingId` و `totalPrice` و `property` إلى `PaymentMethodScreen` (الأسطر 195–208)

### 4.2 Booking Cubit — يعمل ✅
- **الملف:** `lib/features/booking/cubit/booking_cubit.dart`
- **التقييم:** يستدعي `UserService.createBooking()` ويترجم الأخطاء بشكل صحيح باستخدام `ServerException`. ✅

### 4.3 Payment Method Screen — يعمل جزئيًا ⚠️
- **الملف:** `lib/features/booking/presentation/screens/payment_method_screen.dart`
- **التقييم:**
  - ✅ يحتوي على Stripe, PayPal, SADAD
  - ✅ لا يوجد Apple Pay / Google Pay (مطابق للخطة)
  - ✅ كل طريقة تستدعي الخدمة الصحيحة
  - ⚠️ `_stripeService.processPayment()` يُستدعى بدون `customerEmail` صريح (يُمرر `null` إذا لم يكن هناك بريد)

### 4.4 WebView Screens — مكسورة بسبب dependency مفقود ❌
- **الملفات:**
  - `lib/features/booking/presentation/screens/sadad_webview_screen.dart`
  - `lib/features/booking/presentation/screens/paypal_webview_screen.dart`
- **التقييم:** الكود منطقيًا سليم — يعالج redirects ويستدعي `PaymentService`. لكن **لا يمكن بناؤها** بسبب `webview_flutter` المفقود.

### 4.5 Booking Confirmation — يعمل ✅
- **الملف:** `lib/features/booking/presentation/screens/booking_confirmation_screen.dart`
- **التقييم:**
  - ✅ يستدعي `_userService.getBookingDetails(bookingId)` (السطر 43)
  - ✅ يعرض بيانات حقيقية
  - ⚠️ زر "View My Trips" ينتقل إلى `Routes.tripDetails` مع `arguments: _booking!.toJson()` — قد يسبب crash إذا كانت الشاشة التالية تتوقع `bookingId` فقط.
  - ⚠️ زرا "Download" و "Share" وهميان — يظهران `SnackBar("coming soon")` فقط.

---

## 5. تدقيق تدفق المضيف (Host Flow)

### 5.1 Host Service — موجود ✅
- **الملف:** `lib/core/services/host_service.dart`
- **التقييم:** يحتوي على جميع النقاط المطلوبة (`createListing`, `saveDraft`, `uploadPhoto`, `getHostListings`, `getHostBookings`, `getHostStats`, `updateListing`, `deleteListing`). ✅

### 5.2 Host Dashboard — يعمل لكن بدون تفاعل ⚠️
- **الملف:** `lib/features/host/presentation/screens/host_dashboard_screen.dart`
- **التقييم:**
  - ✅ `HostDashboardCubit` يستدعي APIs حقيقية
  - ✅ يعرض بيانات حقيقية (properties, bookings, stats)
  - ❌ بطاقات الإحصائيات (`_buildStatCard`) لديها `onTap: () {}` فارغة — غير قابلة للنقر (الأسطر 141, 148, 157, 164)
  - ⚠️ لا يوجد tab للمضيف في Bottom Navigation — يمكن الوصول إليه فقط من Profile → Host Dashboard

### 5.3 Property Wizard — placeholder وهمي ❌
- **الملف:** `lib/features/host/presentation/screens/property_wizard_screen.dart`
- **المشكلة:** الشاشة الرئيسية مجرد:
```dart
body: const Center(
  child: Text('Property Wizard'),
),
```
- **الملفات الفرعية:** 13 خطوة موجودة كملفات منفصلة في `wizard/` (step_01 إلى step_13)
- **المشكلة:** لا يوجد router يؤدي إلى هذه الخطوات. الـ 13 ملفًا "ميتة" — لا يُستورد أي منها في `app_routes.dart`.

### 5.4 Host Bookings — bug حرج في endpoint ❌
- **الملف:** `lib/features/host/cubit/host_bookings_cubit.dart`
- **المشكلة:** `acceptBooking` و `cancelBooking` تستدعيان:
```dart
await _hostService.updateListing(bookingId, {'status': 'CONFIRMED'});
```
- **السطر:** 48 و 57
- **التأثير:** هذا **endpoint خاطئ**. `updateListing` هو `/property-manager/$listingId` — يُحدث بيانات العقار، **وليس** حالة الحجز. يجب استخدام endpoint خاص بالحجوزات مثل `/booking-manager/$bookingId/status`.
- **التأثير الإضافي:** إذا نجح الطلب، سيُغير حالة العقار نفسه بدلًا من الحجز.

---

## 6. تدقيق الملف الشخصي والدردشة والإشعارات والبحث

### 6.1 Profile Settings

#### Personal Information — يعمل ✅
- **الملف:** `lib/features/profile/presentation/screens/personal_information_screen.dart`
- **التقييم:**
  - ✅ يحمل البيانات عبر `PersonalInfoCubit.loadProfile()`
  - ✅ يحفظ عبر API
  - ⚠️ بعض الحقول (مثل `_phoneController`) لا تُملأ من API — تبدأ فارغة دائمًا

#### KYC Verification — موجود وموصول ✅
- **الملف:** `lib/features/profile/presentation/screens/kyc_verification_screen.dart`
- **التقييم:**
  - ✅ UI كامل مع 3 خطوات (اختيار نوع المستند، رفع صور، selfie)
  - ✅ يستخدم `image_picker` لالتقاط الصور
  - ✅ موصول من Profile → KYC Verification

#### Saved Addresses — موجود لكن غير مُختبر ⚠️
- **الملف:** `lib/features/profile/presentation/screens/saved_addresses_screen.dart`
- **التقييم:** UI موجود وموصول. لم يتم التحقق من اكتمال API integration.

#### Payment Methods — أكواد وهمية ❌
- **الملف:** `lib/features/profile/presentation/screens/payment_methods_screen.dart`
- **المشاكل:**
  - ❌ "إضافة بطاقة ائتمان" — dialog وهمي. عند الضغط على "إضافة" يظهر `SnackBar('تم إضافة البطاقة')` فقط بدون استدعاء API (السطر 375)
  - ❌ "ربط PayPal" — يظهر `SnackBar('ربط PayPal قريباً')` (السطر 290)
  - ❌ "تعيين كافتراضي" — يظهر `SnackBar` فقط بدون استدعاء API (السطر 238)

### 6.2 Chat & Messages — يعمل بشكل أفضل مما توقعته ✅
- **الملف:** `lib/features/chat/presentation/cubit/chat_cubit.dart`
- **التقييم:**
  - ✅ يستخدم `SocketService` للاتصال بالوقت الفعلي (contrary to preliminary finding)
  - ✅ يحتوي على fallback إلى HTTP REST عند انقطاع الـ socket
  - ✅ يدعم typing indicators و read receipts
- **الملف:** `lib/core/services/socket_service.dart`
- **التقييم:**
  - ✅ يتصل بـ Socket.IO ويستمع للأحداث (`new_message`, `message_read`, `user_typing`)
  - ⚠️ لا يتم استدعاء `connectToSocket` من أي مكان واضح في الكود — يحتاج إلى init في `ChatCubit` أو عند فتح التطبيق

### 6.3 Notifications — crash فوري ❌
- **الملف:** `lib/features/notifications/cubit/notifications_cubit.dart`
- **المشكلة:** السطر 16:
```dart
final userId = _userSession.id;
```
- **التأثير:** `UserSession` لا يحتوي على getter `id` — الخاصية الموجودة هي `userId`. هذا خطأ compile-time/syntax error سيمنع البناء، أو runtime crash إذا كان Dart يتجاهل static analysis.
- **الأسطر المتأثرة:** 16, 43

### 6.4 Search & Discovery

#### SearchCubit — يدعم pagination ✅
- **الملف:** `lib/features/properties/cubit/search_cubit.dart`
- **التقييم:**
  - ✅ يدعم `loadMore()` مع زيادة `page` (الأسطر 33–75)
  - ✅ يدعم toggle favorite

#### Property Details — يحمل بيانات حقيقية ✅
- **الملف:** `lib/features/property_details/presentation/cubit/property_details_cubit.dart`
- **التقييم:**
  - ✅ يستدعي `PropertyService.getPropertyById()`
  - ✅ يدعم pagination للتقييمات عبر `loadRatings()`
  - ✅ يحمل التوفر عبر `loadAvailability()`

#### Advanced Filters — كامل ✅
- **الملف:** `lib/features/search/presentation/screens/advanced_filters_screen.dart`
- **التقييم:**
  - ✅ نطاق السعر (RangeSlider)
  - ✅ عدد الغرف والحمامات (counter)
  - ✅ الحد الأدنى للتقييم (Slider 0–5)
  - ✅ نوع العقار (13 نوعًا)
  - ✅ المرافق (27 مرفقًا)

---

## 7. تدقيق المصادقة والجلسة (Auth & Session)

### 7.1 AuthInterceptor — لا يضيف Bearer Token ❌
- **الملف:** `lib/core/network/api/auth_interceptor.dart`
- **المشكلة:** السطر 15–19:
```dart
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (kDebugMode) {
    debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
  }
  handler.next(options);
}
```
- **التأثير:** **لا يوجد `Authorization: Bearer {token}` header في أي طلب API**. جميع طلبات API بعد تسجيل الدخول تُرسل بدون مصادقة.
- **التصحيح المطلوب:**
```dart
final token = _userSession.sessionId; // أو sessionToken
if (token != null && token.isNotEmpty) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

### 7.2 UserSession — يخزن `sessionId` وليس `sessionToken` ⚠️
- **الملف:** `lib/core/services/user_session.dart`
- **التقييم:**
  - ✅ يخزن `userId`, `email`, `firstName`, `lastName`, `sessionId`
  - ⚠️ لا يوجد `sessionToken`. الاسم `sessionId` قد يكون صحيحًا لـ Clerk، لكن يجب توضيح ما إذا كان هذا هو ما يتوقعه الباك-إند كـ Bearer token.

### 7.3 OTP Verification Flow — موجود ✅
- **الملف:** `lib/features/auth/presentation/cubit/auth_cubit.dart`
- **التقييم:**
  - ✅ `verifyOTP()` (الأسطر 177–194)
  - ✅ `preparePhoneVerification()` (الأسطر 196–209)
  - ✅ `verifyEmailCode()` و `resendEmailCode()` (الأسطر 127–173)
  - ✅ 2FA / Second Factor مدعوم (الأسطر 213–249)

### 7.4 Social Login — Google معطل ❌
- **الملف:** `lib/features/auth/presentation/cubit/auth_cubit.dart`
- **المشكلة:** `signInWithGoogle()` (الأسطر 300–323) **معلّق بالكامل**:
```dart
Future<void> signInWithGoogle() async {
  // all code commented out
}
```
- **التأثير:** زر تسجيل الدخول عبر Google موجود في UI لكنه لا يفعل شيئًا.

---

## 8. تدقيق التنقل والوصول (Navigation & Reachability)

### 8.1 Bottom Navigation — لا يحتوي على Host Dashboard ⚠️
- **الملف:** `lib/features/bottom_nav/presentation/screen/bottom_nav.dart`
- **التقييم:**
  - التبويبات: Home, Search, Country, Trips, Profile
  - ❌ لا يوجد "Host Dashboard" في الـ Bottom Nav
  - ✅ يمكن الوصول إليه فقط من Profile → Host Dashboard

### 8.2 Dead Routes / شاشات unreachable ❌
الراوتس التالية مُعرّفة في `routes.dart` لكن **لا يوجد أي `Navigator.pushNamed`** إليها من مسارات المستخدم العادية:

| Route | المسار | المشكلة |
|-------|--------|---------|
| `home` | `/home` | غير مستخدم — BottomNav يستخدم `_screens` مباشرة |
| `photoGallery` | `/photo-gallery` | الشاشة موجودة لكن لا أحد يتصل بها |
| `amenities` | `/amenities` | الشاشة موجودة لكن لا أحد يتصل بها |
| `reviews` | `/reviews` | الشاشة موجودة لكن لا أحد يتصل بها |
| `locationMap` | `/location-map` | الشاشة موجودة لكن لا أحد يتصل بها |
| `dateSelection` | `/date-selection` | لا يُستدعى إلا من AllScreensDemo |
| `guestSelection` | `/guest-selection` | لا يُستدعى إلا من AllScreensDemo |
| `payment` | `/payment` | لا يُستدعى مطلقًا |
| `upcomingTrips` | `/upcoming-trips` | لا يُستدعى مطلقًا |
| `pastTrips` | `/past-trips` | لا يُستدعى مطلقًا |
| `chat` | `/chat` | لا يُستدعى مطلقًا |
| `hostReviews` | `/host-reviews` | لا يُستدعى مطلقًا |
| `reviewProperty` | `/review-property` | لا يُستدعى إلا من AppRoutes (لا push) |
| `propertyWizard` | `/property-wizard` | يُستدعى من AppRoutes لكن الشاشة placeholder |
| `cityList` | `/city-list` | لا يُستدعى إلا من AppRoutes |
| `allScreensDemo` | `/all-screens-demo` | شاشة تجريبية فقط |

### 8.3 Cubits غير مسجلة في Dependency Injection — crash حتمي ❌
- **الملف:** `lib/core/injection/injection_container.dart`
- **المشكلة:** الدالة `init()` **لا تستدعي**:
  - `initHost()`
  - `initNotifications()`
  - `initProfile()`
- **التأثير:** عند محاولة فتح هذه الشاشات، سيحدث خطأ `GetIt`:
  ```
  Error: Object/factory with type HostBookingsCubit is not registered inside GetIt
  ```
- **الشاشات المتأثرة:**
  - Host Dashboard / Host Bookings (تحتاج `HostBookingsCubit`)
  - Notifications (تحتاج `NotificationsCubit`)
  - KYC Verification (تحتاج `KycCubit`)
  - Saved Addresses (تحتاج `SavedAddressesCubit`)
  - Payment Methods (تحتاج `PaymentMethodsCubit`)
  - Property Wizard (تحتاج `ListingWizardCubit`)

---

## 9. تدقيق الهياكل العظمية وأخطاء الشبكة (Skeletons & Network Errors)

### 9.1 Skeleton Loaders — موجودة ويُستخدم بعضها ✅/⚠️
- **الملفات:**
  - `lib/shared/widgets/skeletons/list_skeleton.dart` ✅ تُستخدم في `HomeScreen` و `PropertiesScreen`
  - `lib/shared/widgets/skeletons/property_skeleton.dart` ⚠️ معرّفة لكن غير مستخدمة في الشاشات الرئيسية
  - `lib/shared/widgets/skeletons/trip_skeleton.dart` ⚠️ معرّفة لكن غير مستخدمة
  - `lib/shared/widgets/skeletons/message_skeleton.dart` ⚠️ معرّفة لكن غير مستخدمة

### 9.2 NoInternetConnectionWidget — ميتة ❌
- **الملف:** `lib/core/widgets/no_internet_connection_widget.dart`
- **المشكلة:** **لا يتم استخدامها في أي شاشة**. لم يتم العثور على أي `import` أو استخدام لها خارج تعريفها.
- **التأثير:** عند انقطاع الإنترنت، تظهر أخطاء raw أو screens فارغة بدلاً من widget مصمم.

---

## 10. حالة التحقق المرئي (Visual Verification Status)

### هل التحقق المرئي ممكن؟

**لا.** التحقق المرئي غير ممكن في البيئة الحالية. السبب الرئيسي هو عدم توافق إصدار Dart SDK (`3.2.0` vs `^3.6.0`) مما يمنع `flutter pub get` وبالتالي يمنع بناء التطبيق أو تشغيله. التدقيق تم بالكامل عبر فحص الكود الثابت (static code inspection) مع محاولة `flutter pub get` حيث أمكن.

لو تم إصلاح مشكلة الـ SDK، سيظل هناك **منع بناء** بسبب `webview_flutter` المفقود.

---

## 11. التوصيات والإصلاحات ذات الأولوية

### Priority P0 (يجب إصلاحها قبل أي شيء)

1. **إصلاح Dart SDK constraint**
   - `pubspec.yaml` السطر 8: غيّر `sdk: ^3.6.0` إلى `sdk: '>=3.0.0 <4.0.0'` أو قم بترقية بيئة Flutter إلى 3.24+.

2. **إضافة `webview_flutter` إلى `pubspec.yaml`**
   - أضف: `webview_flutter: ^4.8.0` (أو الإصدار المناسب)

3. **إصلاح `AuthInterceptor` لإضافة Bearer Token**
   - `lib/core/network/api/auth_interceptor.dart`: أضف `Authorization` header في `onRequest`.

4. **إصلاح crash `NotificationsCubit`**
   - `lib/features/notifications/cubit/notifications_cubit.dart` الأسطر 16 و 43: غيّر `_userSession.id` إلى `_userSession.userId`.

5. **تسجيل missing injection modules**
   - `lib/core/injection/injection_container.dart`: أضف:
     ```dart
     await initHost();
     await initNotifications();
     await initProfile();
     ```

### Priority P1 (حرجة للوظائف)

6. **إصلاح `HostBookingsCubit.acceptBooking` endpoint**
   - غيّر `_hostService.updateListing(bookingId, ...)` إلى endpoint صحيح للحجوزات.

7. **إصلاح routes硬编码**
   - استبدل جميع السلاسل النصية في `Navigator.pushNamed` بـ `Routes.xxx` constants.

8. **إزالة الأكواد الوهمية في PaymentMethodsScreen**
   - استبدل `SnackBar` الوهمية باستدعاءات API حقيقية لإضافة/حذف/تعيين افتراضي.

9. **استخدام `NoInternetConnectionWidget`**
   - أضف check للاتصال قبل كل API call واعرض الـ widget عند الانقطاع.

### Priority P2 (تحسين الجودة)

10. **عدم ابتلاع الأخطاء في Services**
    - استبدل `catch (_) { return []; }` بـ `rethrow` أو throw custom exceptions.

11. **إكمال Property Wizard**
    - ربط الـ 13 خطوة بـ `PropertyWizardScreen` أو استبدالها بـ Stepper حقيقي.

12. **تفعيل Google Sign-In**
    - إلغاء التعليق على كود `signInWithGoogle()` في `AuthCubit`.

13. **إضافة Host Dashboard إلى Bottom Navigation**
    - إضافة تبويب "Host" يظهر فقط للمستخدمين المسجلين كمضيفين.

14. **استخدام Skeletons في المزيد من الشاشات**
    - `TripSkeletonCard`, `MessageSkeletonItem`, `PropertySkeletonCard` موجودة لكنها لا تُستخدم.

---

## ملحق: ملخص الأرقام

| الفئة | النتيجة |
|-------|---------|
| نسبة الملفات الموجودة | ~75% |
| نسبة الميزات العاملة | ~30% |
| blockers تمنع البناء | 3 (SDK, webview, NotificationsCubit compile error) |
| crashs حتمية في runtime | 2+ (NotificationsCubit, missing DI modules) |
| bugs في API endpoints | 1 (HostBookingsCubit) |
| شاشات placeholder | 1 (PropertyWizardScreen) |
| dead routes | ~16 |
| dependencies مفقودة | 1 (`webview_flutter`) |
| أكواد وهمية (stub) | 3+ (PaymentMethods add-card, PayPal link, BookingConfirmation download/share) |
