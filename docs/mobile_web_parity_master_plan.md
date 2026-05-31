# خطة الهجرة الشاملة — تطبيق Houseiana Mobile
## توافق التطبيق مع المشروع Web (Next.js)

> **الإصدار:** 2.0 — مُراجَع ومُصحَّح بعد فحص الكود الفعلي  
> **التاريخ:** 2026-04-23  
> **اللغة:** Dart / Flutter  
> **المرجع الثابت:** مشروع الويب (Next.js) — لا يُعدَّل أبدًا

---

## 1. ملخص تنفيذي

التطبيق المحمول يملك هيكلًا بنيويًا سليمًا (BLoC + GetIt + named routes) لكنه يعاني من فجوات وظيفية جوهرية مقارنةً بالموقع الإلكتروني. أبرز الفجوات:

| المجال | الحالة |
|--------|--------|
| دورة الحجز كاملة | مكسورة — لا يوجد API call لإنشاء الحجز |
| بوابات الدفع | خاطئة — Apple Pay/Google Pay بدلًا من SADAD |
| معالج بيانات المستضيف | غائب كليًا (13 خطوة مفقودة) |
| لوحة تحكم المستضيف | واجهة ثابتة بدون بيانات حقيقية |
| معالجة الأخطاء | صامتة على مستوى الخدمات |
| النماذج المكتوبة | غير موجودة — كل شيء `Map<String, dynamic>` |

---

## 2. بنية المشروع الحالية

```
lib/
├── core/
│   ├── constants/
│   │   ├── routes/          # routes.dart + app_routes.dart
│   │   ├── app_colors.dart
│   │   └── app_config.dart  # dev/staging/prod
│   ├── injection/
│   │   └── injection_container.dart  # GetIt (sl)
│   ├── network/
│   │   └── api/dio_consumer.dart     # يرمي ServerException صحيح
│   └── services/
│       ├── user_service.dart         # أخطاء صامتة على مستوى catch
│       ├── payment_service.dart      # Stripe + PayPal + SADAD
│       ├── user_session.dart         # SharedPreferences
│       └── fcm_service.dart
├── features/
│   ├── auth/
│   ├── booking/
│   ├── host/
│   ├── profile/
│   ├── trips/
│   └── ...
└── main.dart
```

---

## 3. تصحيحات الخطة السابقة (نتائج فحص الكود)

### ✅ تصحيح 1 — DioConsumer لا يبتلع الأخطاء
**الخطأ السابق:** قيل إن `DioConsumer` يبتلع الأخطاء بصمت.  
**الواقع:** `DioConsumer.request()` يرمي `ServerException` بشكل صحيح.  
**المشكلة الفعلية:** على مستوى `UserService`، الـ `catch` يعيد `null` أو `[]` بدلًا من إعادة رمي الخطأ:
```dart
// مثال من user_service.dart — المشكلة هنا:
} catch (_) { return null; }
```

### ✅ تصحيح 2 — SADAD يعيد paymentUrl وليس Form Data
**الخطأ السابق:** افتراض أن SADAD يعيد `formAction + formData` مثل الويب.  
**الواقع:** `payment_service.dart`:
```dart
Future<String?> createSadadPayment({...}) async {
  // ...
  return response['paymentUrl'];  // فقط URL
}
```
**الحل:** فتح WebView بالـ `paymentUrl` مباشرةً — أبسط من الويب.

### ✅ تصحيح 3 — BookingRequestScreen لا ينشئ حجزًا أبدًا
**الخطأ السابق:** قيل "الواجهة جاهزة والدفع مفقود فقط."  
**الواقع:** الزر لا يستدعي `createBooking()` إطلاقًا — ينتقل مباشرةً لشاشة الدفع.  
الرسوم مُشفَّرة: `cleaningFee = $50`، `serviceFee = 10%` — ليست من بيانات العقار.

### ✅ تصحيح 4 — PaymentMethodScreen يعرض طرق دفع خاطئة
**الخطأ السابق:** قيل "طرق الدفع موجودة لكن بدون API."  
**الواقع:** الشاشة تعرض Apple Pay و Google Pay — لا يدعمهما الـ backend.  
**المفقود كليًا:** SADAD — وهو بوابة الدفع الرئيسية للسوق الخليجي.

### ✅ تصحيح 5 — ListPropertyScreen لديها 3 خطوات فقط (ليس 5)
**الخطأ السابق:** "~5 خطوات جزئية."  
**الواقع:** 3 خطوات فقط: النوع، التفاصيل الأساسية، المرافق — بدون أي API.  
**المطلوب فعليًا:** 10 خطوات جديدة كاملة لمطابقة معالج الويب.

---

## 4. خارطة المهام الكاملة

### المرحلة الأولى — الأساس (يجب إنجازها أولًا)

---

#### TASK-001 — نماذج البيانات المكتوبة (Typed Models)

**الأولوية:** حرجة  
**الجهد:** 3 أيام

**المشكلة:** كل البيانات تُمرَّر كـ `Map<String, dynamic>` مما يجعل الكود هشًا وصعب الصيانة.

**المطلوب إنشاؤه:**

```
lib/core/models/
├── property_model.dart
├── booking_model.dart
├── user_model.dart
├── review_model.dart
├── trip_model.dart
└── payment_result_model.dart
```

**مثال النموذج:**
```dart
class BookingModel {
  final String id;
  final String propertyId;
  final String userId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status;

  const BookingModel({...});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['_id'] ?? json['id'] ?? '',
    propertyId: json['property'] is Map
        ? (json['property']['_id'] ?? '') 
        : (json['property'] ?? ''),
    userId: json['user'] ?? '',
    checkIn: DateTime.parse(json['checkInDate'] ?? json['checkIn']),
    checkOut: DateTime.parse(json['checkOutDate'] ?? json['checkOut']),
    guests: json['guests'] ?? 1,
    totalPrice: double.tryParse('${json['totalPrice']}') ?? 0.0,
    status: json['status'] ?? 'PENDING',
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'property': propertyId,
    'checkInDate': checkIn.toIso8601String(),
    'checkOutDate': checkOut.toIso8601String(),
    'guests': guests,
    'totalPrice': totalPrice,
    'status': status,
  };
}
```

**الملفات التي تحتاج تحديثًا بعد إنشاء النماذج:**
- `user_service.dart` — استبدال `Map<String, dynamic>` بالنماذج
- `trips_screen.dart` — استخدام `TripModel` بدلًا من `Map`
- `trip_details_screen.dart` — نفس الأمر
- `booking_request_screen.dart` — استخدام `BookingModel`

---

#### TASK-002 — إصلاح معالجة الأخطاء في طبقة الخدمات

**الأولوية:** حرجة  
**الجهد:** 1 يوم

**المشكلة:** جميع دوال `UserService` تبتلع الأخطاء بصمت:
```dart
} catch (_) { return null; }   // المشكلة
} catch (_) { return []; }     // المشكلة
```

**الحل:**
```dart
// في user_service.dart — كل دالة تُعدَّل هكذا:
Future<BookingModel?> createBooking(Map<String, dynamic> data) async {
  try {
    final response = await _dio.request(
      url: '/booking-manager',
      method: RequestMethod.post,
      body: data,
    );
    return BookingModel.fromJson(response as Map<String, dynamic>);
  } on ServerException catch (e) {
    // أعِد الرمي — دع الـ BLoC يتعامل معه
    rethrow;
  }
}
```

**الدوال التي تحتاج إصلاحًا:**
- `createBooking()` — حاليًا تعيد `null` عند الخطأ
- `getTrips()` — تعيد `[]` عند الخطأ بدون إشعار المستخدم
- `cancelBooking()` — تعيد `false` بدون سبب
- `getPropertyDetails()` — تعيد `null` بصمت

---

#### TASK-003 — إضافة مسارات (Routes) المفقودة

**الأولوية:** عالية  
**الجهد:** نصف يوم

**المفقود في `routes.dart`:**

```dart
// أضف في class Routes:
static const String hostBookings = '/host-bookings';
static const String hostReviews = '/host-reviews';
static const String reviewProperty = '/review-property';
static const String sadadWebView = '/sadad-webview';
static const String paypalWebView = '/paypal-webview';
static const String propertyWizard = '/property-wizard';
```

**أضف في `app_routes.dart`:**
```dart
case Routes.hostBookings:
  return _buildRoute(const HostBookingsScreen(), settings);
case Routes.hostReviews:
  return _buildRoute(const HostReviewsScreen(), settings);
case Routes.sadadWebView:
  final args = settings.arguments as Map<String, dynamic>?;
  return _buildRoute(
    SadadWebViewScreen(paymentUrl: args?['paymentUrl'] ?? ''),
    settings,
  );
case Routes.paypalWebView:
  final args = settings.arguments as Map<String, dynamic>?;
  return _buildRoute(
    PaypalWebViewScreen(approvalUrl: args?['approvalUrl'] ?? ''),
    settings,
  );
```

---

### المرحلة الثانية — دورة الحجز والدفع (حرجة جدًا)

---

#### TASK-010 — إصلاح BookingRequestScreen (لا يُنشئ حجزًا)

**الأولوية:** حرجة جدًا  
**الجهد:** 2 يوم  
**الملف:** `lib/features/booking/presentation/screens/booking_request_screen.dart`

**المشاكل الحالية:**
1. زر "طلب الحجز" ينتقل مباشرةً لشاشة الدفع بدون استدعاء API
2. `cleaningFee` مُشفَّرة بـ `$50`
3. `serviceFee` مُشفَّرة بـ `10%`
4. لا يوجد BLoC لإدارة الحالة

**الحل الكامل:**

**أ) إنشاء BookingCubit:**
```dart
// lib/features/booking/cubit/booking_cubit.dart
class BookingCubit extends Cubit<BookingState> {
  final UserService _userService;
  BookingCubit(this._userService) : super(BookingInitial());

  Future<void> createBooking({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    emit(BookingLoading());
    try {
      final booking = await _userService.createBooking({
        'property': propertyId,
        'checkInDate': checkIn.toIso8601String(),
        'checkOutDate': checkOut.toIso8601String(),
        'guests': guests,
      });
      if (booking != null) {
        emit(BookingCreated(booking));
      } else {
        emit(const BookingError('فشل إنشاء الحجز'));
      }
    } on ServerException catch (e) {
      emit(BookingError(e.message));
    }
  }
}
```

**ب) تعديل الشاشة:**
```dart
// في BookingRequestScreen:
// 1. اقرأ رسوم الخدمة والتنظيف من args['property']
final fees = property['fees'] as Map? ?? {};
final cleaningFee = double.tryParse('${fees['cleaning'] ?? 0}') ?? 0;
final serviceFee = double.tryParse('${fees['service'] ?? 0}') ?? 0;

// 2. عند الضغط على "طلب الحجز":
BlocProvider.of<BookingCubit>(context).createBooking(
  propertyId: property['_id'],
  checkIn: checkIn,
  checkOut: checkOut,
  guests: guests,
);

// 3. عند BookingCreated، انتقل لشاشة الدفع مع الـ bookingId:
Navigator.pushNamed(
  context, 
  Routes.paymentMethod,
  arguments: {'bookingId': booking.id, 'totalPrice': booking.totalPrice},
);
```

---

#### TASK-011 — إصلاح PaymentMethodScreen (طرق دفع خاطئة)

**الأولوية:** حرجة جدًا  
**الجهد:** 2 يوم  
**الملف:** `lib/features/booking/presentation/screens/payment_method_screen.dart`

**المشاكل الحالية:**
1. يعرض Apple Pay — غير مدعوم في الـ backend
2. يعرض Google Pay — غير مدعوم في الـ backend
3. SADAD مفقود كليًا
4. لا يستدعي أي API

**الطرق الصحيحة المدعومة:**

| الطريقة | API Endpoint | المعالجة |
|---------|-------------|---------|
| بطاقة ائتمانية (Stripe) | `/api/stripe/create-intent` → `/api/stripe/confirm` | في التطبيق مباشرةً |
| PayPal | `/api/paypal/create-order` → `/api/paypal/capture-order/{id}` | WebView بـ approvalUrl |
| SADAD | `/api/sadadpayment/initiate` | WebView بـ paymentUrl |

**تدفق Stripe الجديد:**
```dart
// 1. استدعِ createStripePaymentIntent
final clientSecret = await _paymentService.createStripePaymentIntent(
  amount: totalPrice,
  bookingId: bookingId,
);
// 2. استخدم flutter_stripe لعرض نموذج الدفع
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    paymentIntentClientSecret: clientSecret,
    merchantDisplayName: 'Houseiana',
  ),
);
await Stripe.instance.presentPaymentSheet();
// 3. عند النجاح، أكِّد عبر:
await _paymentService.confirmStripePayment(paymentIntentId: ...);
```

**تدفق SADAD الجديد:**
```dart
// 1. استدعِ createSadadPayment
final paymentUrl = await _paymentService.createSadadPayment(
  bookingId: bookingId,
  amount: totalPrice,
  customerName: userName,
  customerEmail: userEmail,
);
// 2. افتح WebView
if (paymentUrl != null) {
  Navigator.pushNamed(
    context,
    Routes.sadadWebView,
    arguments: {'paymentUrl': paymentUrl, 'bookingId': bookingId},
  );
}
```

**تدفق PayPal الجديد:**
```dart
// 1. أنشئ الطلب
final order = await _paymentService.createPayPalOrder(
  amount: totalPrice,
  bookingId: bookingId,
);
// 2. افتح WebView بـ approvalUrl
Navigator.pushNamed(
  context,
  Routes.paypalWebView,
  arguments: {
    'approvalUrl': order['approvalUrl'],
    'orderId': order['orderId'],
  },
);
```

---

#### TASK-012 — إنشاء SadadWebViewScreen

**الأولوية:** عالية  
**الجهد:** 1 يوم  
**ملف جديد:** `lib/features/booking/presentation/screens/sadad_webview_screen.dart`

```dart
import 'package:webview_flutter/webview_flutter.dart';

class SadadWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;
  const SadadWebViewScreen({
    super.key, 
    required this.paymentUrl,
    required this.bookingId,
  });

  @override
  State<SadadWebViewScreen> createState() => _SadadWebViewScreenState();
}

class _SadadWebViewScreenState extends State<SadadWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // اكتشف إعادة التوجيه للنجاح أو الفشل
            final url = request.url;
            if (url.contains('/payment-success') || url.contains('success=true')) {
              Navigator.pushReplacementNamed(
                context,
                Routes.bookingConfirmation,
                arguments: {'bookingId': widget.bookingId},
              );
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment-failed') || url.contains('success=false')) {
              Navigator.pushReplacementNamed(context, Routes.paymentFailed);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الدفع'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(
            context, Routes.paymentCancel,
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
```

---

#### TASK-013 — إنشاء PaypalWebViewScreen

**الأولوية:** عالية  
**الجهد:** 1 يوم  
**ملف جديد:** `lib/features/booking/presentation/screens/paypal_webview_screen.dart`

مشابه لـ `SadadWebViewScreen` لكن:
- يستدعي `capturePayPalOrder(orderId)` عند اكتشاف `paypal.com/checkoutnow` redirect
- ينتقل لـ `bookingConfirmation` عند النجاح

---

#### TASK-014 — إنشاء BookingConfirmationScreen الكاملة

**الأولوية:** عالية  
**الجهد:** 1 يوم

الشاشة الحالية ثابتة. يجب:
1. قراءة تفاصيل الحجز من الـ API بـ `bookingId`
2. عرض رقم الحجز، العقار، التواريخ، المبلغ المدفوع
3. زر "عرض رحلتي" ينتقل لـ `Routes.tripDetails`
4. زر "العودة للرئيسية" ينتقل لـ `Routes.bottomNav`

---

### المرحلة الثالثة — معالج قائمة العقارات (Host Listing Wizard)

---

#### TASK-020 — إعادة هيكلة معالج قائمة العقارات (13 خطوة)

**الأولوية:** عالية  
**الجهد:** 8 أيام

**الحالة الحالية:** 3 خطوات محلية بدون API  
**المطلوب:** 13 خطوة مع حفظ تدريجي (draft saving)

**هيكل الخطوات الجديد:**

```
lib/features/host/
├── cubit/
│   ├── listing_wizard_cubit.dart
│   └── listing_wizard_state.dart
└── presentation/
    └── screens/
        ├── wizard/
        │   ├── step_01_property_type_screen.dart
        │   ├── step_02_property_kind_screen.dart    (كامل/خاص/مشترك)
        │   ├── step_03_location_screen.dart          (خريطة)
        │   ├── step_04_basics_screen.dart            (غرف/حمامات/ضيوف)
        │   ├── step_05_amenities_screen.dart
        │   ├── step_06_photos_screen.dart            (رفع صور)
        │   ├── step_07_title_screen.dart
        │   ├── step_08_description_screen.dart
        │   ├── step_09_highlights_screen.dart
        │   ├── step_10_house_rules_screen.dart
        │   ├── step_11_pricing_screen.dart
        │   ├── step_12_availability_screen.dart
        │   └── step_13_review_publish_screen.dart
        └── list_property_screen.dart     (المنسق/الـ wrapper)
```

**ListingWizardCubit:**
```dart
class ListingWizardCubit extends Cubit<ListingWizardState> {
  final HostService _hostService;
  
  ListingWizardCubit(this._hostService) : super(ListingWizardState.initial());

  // الحفظ التدريجي — يُستدعى عند انتهاء كل خطوة
  Future<void> saveDraft() async {
    try {
      final draftId = await _hostService.saveDraft(state.data);
      emit(state.copyWith(draftId: draftId));
    } on ServerException {
      // حفظ محلي مؤقت فقط — لا نعيق المستخدم
    }
  }

  Future<void> publishListing() async {
    emit(state.copyWith(isPublishing: true));
    try {
      final listing = await _hostService.createListing(state.data);
      emit(state.copyWith(publishedListing: listing, isPublishing: false));
    } on ServerException catch (e) {
      emit(state.copyWith(error: e.message, isPublishing: false));
    }
  }

  void updateStep(int step, Map<String, dynamic> data) {
    emit(state.copyWith(
      currentStep: step,
      data: {...state.data, ...data},
    ));
  }
}
```

**خطوة الصور (Step 06) — رفع متعدد:**
```dart
Future<void> uploadPhotos(List<XFile> files) async {
  emit(state.copyWith(isUploadingPhotos: true));
  final uploaded = <String>[];
  for (final file in files) {
    final url = await _hostService.uploadPhoto(file);
    if (url != null) uploaded.add(url);
  }
  emit(state.copyWith(
    data: {...state.data, 'photos': uploaded},
    isUploadingPhotos: false,
  ));
}
```

---

#### TASK-021 — إنشاء HostService

**الأولوية:** عالية  
**الجهد:** 2 يوم  
**ملف جديد:** `lib/core/services/host_service.dart`

```dart
class HostService {
  final DioConsumer _dio;
  HostService(this._dio);

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    return await _dio.request(
      url: '/property-manager',
      method: RequestMethod.post,
      body: data,
    ) as Map<String, dynamic>;
  }

  Future<String?> saveDraft(Map<String, dynamic> data) async {
    final res = await _dio.request(
      url: '/property-manager/draft',
      method: RequestMethod.post,
      body: data,
    ) as Map<String, dynamic>;
    return res['_id']?.toString();
  }

  Future<String?> uploadPhoto(XFile file) async {
    // multipart upload
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.request(
      url: '/upload/property-photo',
      method: RequestMethod.post,
      body: formData,
    ) as Map<String, dynamic>;
    return res['url']?.toString();
  }

  Future<List<Map<String, dynamic>>> getHostListings(String hostId) async {
    final res = await _dio.request(
      url: '/property-manager/host/$hostId',
      method: RequestMethod.get,
    );
    if (res is List) {
      return res.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getHostBookings(String hostId) async {
    final res = await _dio.request(
      url: '/booking-manager/host/$hostId',
      method: RequestMethod.get,
    );
    if (res is List) {
      return res.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}
```

---

#### TASK-022 — إنشاء HostBookingsScreen

**الأولوية:** متوسطة  
**الجهد:** 2 يوم  
**ملف جديد:** `lib/features/host/presentation/screens/host_bookings_screen.dart`

الميزات:
- قائمة حجوزات العقارات المملوكة للمستضيف
- فلترة: معلقة / مؤكدة / منتهية
- قبول / رفض الحجوزات المعلقة
- عرض تفاصيل الحجز والمستأجر

---

### المرحلة الرابعة — لوحة تحكم المستضيف

---

#### TASK-030 — ربط HostDashboardScreen بالـ API

**الأولوية:** عالية  
**الجهد:** 2 يوم  
**الملف:** `lib/features/host/presentation/screens/host_dashboard_screen.dart`

**البيانات الحقيقية المطلوبة:**
- إجمالي الإيرادات (من `/booking-manager/host/{id}/stats`)
- عدد الحجوزات النشطة
- تقييم المستضيف الإجمالي
- قائمة العقارات المدرجة
- الحجوزات الأخيرة

**الـ HostDashboardCubit:**
```dart
class HostDashboardCubit extends Cubit<HostDashboardState> {
  Future<void> loadDashboard(String hostId) async {
    emit(HostDashboardLoading());
    try {
      final results = await Future.wait([
        _hostService.getHostListings(hostId),
        _hostService.getHostBookings(hostId),
        _hostService.getHostStats(hostId),
      ]);
      emit(HostDashboardLoaded(
        listings: results[0] as List<Map<String, dynamic>>,
        bookings: results[1] as List<Map<String, dynamic>>,
        stats: results[2] as Map<String, dynamic>,
      ));
    } on ServerException catch (e) {
      emit(HostDashboardError(e.message));
    }
  }
}
```

---

### المرحلة الخامسة — إدارة المستخدم والملف الشخصي

---

#### TASK-040 — PersonalInformationScreen (ربط بالـ API)

**الأولوية:** عالية  
**الجهد:** 1.5 يوم  
**الملف:** `lib/features/profile/presentation/screens/personal_information_screen.dart`

**Endpoints المطلوبة:**
- `GET /user-manager/{id}` — جلب البيانات الحالية
- `PATCH /user-manager/{id}` — تحديث الاسم، الصورة، رقم الهاتف

**رفع صورة الملف الشخصي:**
```dart
Future<void> updateProfilePhoto(XFile file) async {
  final formData = FormData.fromMap({
    'avatar': await MultipartFile.fromFile(file.path),
  });
  await _dio.request(
    url: '/user-manager/${session.userId}/avatar',
    method: RequestMethod.post,
    body: formData,
  );
}
```

---

#### TASK-041 — KycVerificationScreen (ربط بالـ API)

**الأولوية:** متوسطة  
**الجهد:** 2 يوم  
**الملف:** `lib/features/profile/presentation/screens/kyc_verification_screen.dart`

**المطلوب:**
1. رفع صورة الهوية (أمام + خلف)
2. رفع صورة Selfie
3. `POST /user-manager/{id}/kyc` مع الصور
4. متابعة حالة الطلب: `pending / approved / rejected`

---

#### TASK-042 — SavedAddressesScreen (ربط بالـ API)

**الأولوية:** منخفضة  
**الجهد:** 1 يوم

- `GET /user-manager/{id}/addresses`
- `POST /user-manager/{id}/addresses`
- `DELETE /user-manager/{id}/addresses/{addressId}`

---

#### TASK-043 — PaymentMethodsScreen (ربط بالـ API)

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

- `GET /user-manager/{id}/payment-methods`
- `DELETE /user-manager/{id}/payment-methods/{methodId}`
- `POST /user-manager/{id}/payment-methods` (حفظ بطاقة Stripe)

---

### المرحلة السادسة — المراسلات الفورية

---

#### TASK-050 — ربط ChatConversationScreen بـ Socket.IO

**الأولوية:** عالية  
**الجهد:** 3 أيام  
**الملف:** `lib/features/messages/presentation/screens/chat_conversation_screen.dart`

**الحالة الحالية:** واجهة ثابتة بدون بيانات حقيقية.

**المطلوب:**

**أ) إنشاء ChatService:**
```dart
// lib/core/services/chat_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  IO.Socket? _socket;

  void connect(String userId, String token) {
    _socket = IO.io(
      AppConfig.baseUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .build(),
    );
    _socket!.on('connect', (_) => debugPrint('[Socket] Connected'));
    _socket!.on('disconnect', (_) => debugPrint('[Socket] Disconnected'));
  }

  Stream<Map<String, dynamic>> onMessage(String conversationId) {
    final controller = StreamController<Map<String, dynamic>>();
    _socket?.on('message_$conversationId', (data) {
      controller.add(data as Map<String, dynamic>);
    });
    return controller.stream;
  }

  void sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'senderId': senderId,
    });
  }

  void disconnect() => _socket?.disconnect();
}
```

**ب) ChatCubit:**
```dart
class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  StreamSubscription? _subscription;

  Future<void> loadMessages(String conversationId) async {
    emit(ChatLoading());
    try {
      final messages = await _chatService.getMessages(conversationId);
      emit(ChatLoaded(messages: messages));
      // اشترك للرسائل الجديدة
      _subscription = _chatService
          .onMessage(conversationId)
          .listen((msg) => _onNewMessage(msg));
    } on ServerException catch (e) {
      emit(ChatError(e.message));
    }
  }

  void _onNewMessage(Map<String, dynamic> msg) {
    if (state is ChatLoaded) {
      final current = (state as ChatLoaded).messages;
      emit(ChatLoaded(messages: [...current, msg]));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

---

#### TASK-051 — ConversationsScreen (قائمة المحادثات الحقيقية)

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

- `GET /conversation-manager/{userId}` — قائمة المحادثات
- عرض آخر رسالة والوقت
- عداد الرسائل غير المقروءة

---

### المرحلة السابعة — الإشعارات

---

#### TASK-060 — ربط NotificationsScreen بالـ API

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

- `GET /notification-manager/{userId}` — قائمة الإشعارات
- `PATCH /notification-manager/{id}/read` — تعليم كمقروء
- `DELETE /notification-manager/{id}` — حذف إشعار

**FCM موجود ومُهيَّأ** في `fcm_service.dart` — يحتاج فقط ربط deep linking:
```dart
// في FCMService.initialize():
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final data = message.data;
  if (data['type'] == 'booking') {
    navigatorKey.currentState?.pushNamed(
      Routes.tripDetails,
      arguments: {'bookingId': data['bookingId']},
    );
  } else if (data['type'] == 'message') {
    navigatorKey.currentState?.pushNamed(
      Routes.chatConversation,
      arguments: {'conversationId': data['conversationId']},
    );
  }
});
```

---

### المرحلة الثامنة — اكتشاف العقارات

---

#### TASK-070 — ربط SearchPropertiesScreen بالـ API

**الأولوية:** عالية  
**الجهد:** 2 يوم

**الفلاتر المطلوبة (مطابقة للويب):**

```dart
class PropertySearchParams {
  final String? location;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  final String? propertyType;
  final int? minBedrooms;
  final double? minRating;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParams() => {
    if (location != null) 'location': location,
    if (checkIn != null) 'checkIn': checkIn!.toIso8601String(),
    if (checkOut != null) 'checkOut': checkOut!.toIso8601String(),
    if (guests != null) 'guests': guests,
    if (minPrice != null) 'minPrice': minPrice,
    if (maxPrice != null) 'maxPrice': maxPrice,
    if (amenities?.isNotEmpty == true) 'amenities': amenities!.join(','),
    if (propertyType != null) 'type': propertyType,
    if (minBedrooms != null) 'minBedrooms': minBedrooms,
    if (minRating != null) 'minRating': minRating,
    'page': page,
    'limit': limit,
  };
}
```

**Pagination + Infinite Scroll:**
```dart
class SearchCubit extends Cubit<SearchState> {
  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> loadMore() async {
    if (!_hasMore || state is SearchLoadingMore) return;
    emit(SearchLoadingMore(existing: (state as SearchLoaded).properties));
    final results = await _propertyService.searchProperties(
      params.copyWith(page: ++_currentPage),
    );
    _hasMore = results.length == params.limit;
    emit(SearchLoaded(
      properties: [...(state as SearchLoadingMore).existing, ...results],
      hasMore: _hasMore,
    ));
  }
}
```

---

#### TASK-071 — PropertyDetailsScreen (تحميل البيانات الحقيقية)

**الأولوية:** عالية  
**الجهد:** 2 يوم

**المطلوب:**
1. تحميل تفاصيل العقار من `GET /property-manager/{id}`
2. عرض المعرض الكامل للصور (PageView مع dots)
3. عرض التقييمات مع pagination
4. عرض المرافق كاملةً (ليس فقط 6 أولى)
5. التحقق من توفر التواريخ: `GET /property-manager/{id}/availability`
6. عرض الموقع على الخريطة (Google Maps widget)

---

#### TASK-072 — AdvancedFiltersScreen (مزامنة مع الويب)

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

إضافة الفلاتر المفقودة:
- عدد غرف النوم الأدنى (slider)
- نوع العقار (multi-select)
- وسائل الراحة (multi-select)
- تقييم أدنى

---

### المرحلة التاسعة — المصادقة والجلسة

---

#### TASK-080 — مراجعة دورة المصادقة مع Clerk

**الأولوية:** عالية  
**الجهد:** 2 يوم

**التحقق المطلوب:**
- هل `UserSession` يحفظ `sessionToken` أم `userId` فقط؟
- هل يُرسَل `Authorization: Bearer {token}` في كل طلب؟
- هل يوجد `refresh token` logic عند انتهاء الجلسة؟

**إضافة Auth Interceptor في DioConsumer:**
```dart
// في dio_consumer.dart، أضف Interceptor:
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = sl<UserSession>().sessionToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      // حاول تجديد الجلسة
      final refreshed = await sl<AuthService>().refreshSession();
      if (refreshed) {
        // أعد الطلب
        handler.resolve(await _retry(error.requestOptions));
        return;
      }
      // انتهت الجلسة — أعد للـ Login
      sl<NavigationService>().pushNamedAndRemoveUntil(Routes.login);
    }
    handler.next(error);
  },
));
```

---

#### TASK-081 — OTP Verification (التحقق من التدفق الكامل)

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

التحقق من أن `OtpVerificationScreen` يتعامل صحيحًا مع:
- `verifyType: 'phone'` — التحقق من رقم الهاتف
- `verifyType: 'email'` — التحقق من البريد الإلكتروني
- `strategy: 'email_code'` مقابل `strategy: 'phone_code'`
- إعادة الإرسال (Resend OTP) بعد 60 ثانية

---

### المرحلة العاشرة — الجودة والاختبار

---

#### TASK-090 — اختبارات الوحدة للـ BLoC/Cubit

**الأولوية:** متوسطة  
**الجهد:** 3 أيام

**الأولويات:**
1. `BookingCubit` — اختبار حالات النجاح والفشل وإلغاء الحجز
2. `PaymentCubit` (عند إنشائه) — اختبار تدفقات Stripe/PayPal/SADAD
3. `ListingWizardCubit` — اختبار الحفظ التدريجي والنشر
4. `SearchCubit` — اختبار الفلترة والـ pagination

**مثال اختبار:**
```dart
// test/features/booking/booking_cubit_test.dart
void main() {
  late BookingCubit cubit;
  late MockUserService mockService;

  setUp(() {
    mockService = MockUserService();
    cubit = BookingCubit(mockService);
  });

  test('createBooking emits [Loading, Created] on success', () async {
    when(mockService.createBooking(any))
        .thenAnswer((_) async => BookingModel(id: 'booking-123', ...));
    
    expect(
      cubit.stream,
      emitsInOrder([isA<BookingLoading>(), isA<BookingCreated>()]),
    );
    
    await cubit.createBooking(
      propertyId: 'prop-1',
      checkIn: DateTime(2026, 5, 1),
      checkOut: DateTime(2026, 5, 7),
      guests: 2,
    );
  });

  test('createBooking emits [Loading, Error] on ServerException', () async {
    when(mockService.createBooking(any))
        .thenThrow(const ServerException(message: 'Property not available'));
    
    expect(
      cubit.stream,
      emitsInOrder([isA<BookingLoading>(), isA<BookingError>()]),
    );
    
    await cubit.createBooking(
      propertyId: 'prop-1',
      checkIn: DateTime(2026, 5, 1),
      checkOut: DateTime(2026, 5, 7),
      guests: 2,
    );
  });
}
```

---

#### TASK-091 — اختبارات Widget لمسار الحجز

**الأولوية:** متوسطة  
**الجهد:** 2 يوم

```dart
// test/features/booking/booking_request_screen_test.dart
testWidgets('shows loading when booking is being created', (tester) async {
  await tester.pumpWidget(
    BlocProvider<BookingCubit>(
      create: (_) => MockBookingCubit()..mockState(BookingLoading()),
      child: const BookingRequestScreen(),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

### المرحلة الحادية عشرة — تجربة المستخدم

---

#### TASK-100 — الـ Loading States والـ Skeletons

**الأولوية:** متوسطة  
**الجهد:** 2 يوم

**المطلوب:**
- `PropertyCardSkeleton` — بديل الانتظار في قوائم العقارات
- `TripCardSkeleton` — بديل الانتظار في شاشة الرحلات
- `MessageSkeleton` — بديل الانتظار في المحادثات

```dart
// lib/core/widgets/skeletons/property_card_skeleton.dart
class PropertyCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
```

---

#### TASK-101 — معالجة حالات الشبكة المنقطعة

**الأولوية:** متوسطة  
**الجهد:** 1 يوم

```dart
// lib/core/widgets/network_error_widget.dart
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const NetworkErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppColors.neutral400),
          const SizedBox(height: 16),
          const Text('تعذّر الاتصال بالشبكة'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. جدول الأعمدة والتبعيات

```
TASK-001 (النماذج)
    └── TASK-002 (معالجة الأخطاء)
            ├── TASK-010 (إنشاء الحجز)
            │       └── TASK-011 (طرق الدفع)
            │               ├── TASK-012 (SADAD WebView)
            │               ├── TASK-013 (PayPal WebView)
            │               └── TASK-014 (تأكيد الحجز)
            └── TASK-020 (معالج المستضيف)
                    └── TASK-021 (HostService)
                            ├── TASK-022 (حجوزات المستضيف)
                            └── TASK-030 (لوحة التحكم)

TASK-003 (المسارات) ← مستقل، يُنجز مبكرًا
TASK-050 (Socket) ← مستقل
TASK-060 (إشعارات) ← مستقل
TASK-070 (بحث) ← مستقل
TASK-080 (مصادقة) ← مستقل، يُنجز مبكرًا
```

---

## 6. تقدير الجهد الإجمالي

| المرحلة | المهام | الجهد التقديري |
|---------|--------|----------------|
| الأساس | TASK-001 إلى 003 | 4.5 أيام |
| الحجز والدفع | TASK-010 إلى 014 | 7 أيام |
| معالج المستضيف | TASK-020 إلى 022 | 12 يومًا |
| لوحة المستضيف | TASK-030 | 2 يوم |
| الملف الشخصي | TASK-040 إلى 043 | 5.5 أيام |
| المراسلات | TASK-050 إلى 051 | 4 أيام |
| الإشعارات | TASK-060 | 1 يوم |
| الاكتشاف | TASK-070 إلى 072 | 5 أيام |
| المصادقة | TASK-080 إلى 081 | 3 أيام |
| الاختبارات | TASK-090 إلى 091 | 5 أيام |
| تجربة المستخدم | TASK-100 إلى 101 | 3 أيام |
| **الإجمالي** | | **~52 يوم عمل** |

---

## 7. المجهولات والعوائق المتبقية

### عوائق حرجة تحتاج توضيحًا

| # | المجهول | التأثير | الحل المقترح |
|---|---------|---------|-------------|
| 1 | هل `UserSession` يحفظ `sessionToken` الكامل أم `userId` فقط؟ | يؤثر على مصادقة جميع الـ API calls | قراءة `user_session.dart` كاملًا |
| 2 | ما هو نمط redirect URLs لـ SADAD بعد الدفع؟ | يؤثر على منطق `SadadWebViewScreen` | مراجعة توثيق SADAD أو اختبار بيئة dev |
| 3 | هل يوجد endpoint لاسترداد تفاصيل العقار مع توفر التواريخ؟ | يؤثر على `PropertyDetailsScreen` | مراجعة API docs الخلفي |
| 4 | ما هو URL ومتطلبات اتصال Socket.IO؟ | يؤثر على `ChatService` | مراجعة backend team |
| 5 | هل الـ backend يدعم Draft listings؟ | يؤثر على `ListingWizardCubit.saveDraft()` | فحص API docs |
| 6 | ما هي return URLs لـ PayPal (success/cancel)؟ | يؤثر على `PaypalWebViewScreen` | مراجعة `paypal/create-order` response |

### ملاحظات تقنية

- **`webview_flutter`** يجب إضافته لـ `pubspec.yaml` (مطلوب لـ SADAD و PayPal)
- **`socket_io_client`** يجب إضافته لـ `pubspec.yaml` (مطلوب للمحادثات)
- **`shimmer`** مفيد لـ skeleton loading (اختياري)
- قد تحتاج بعض خطوات المعالج لـ **`image_picker`** لرفع الصور (تحقق من pubspec الحالي)

---

## 8. قواعد صارمة للتطبيق

1. **لا تُعدِّل مشروع الويب** — هو المرجع الثابت فقط
2. كل شاشة جديدة تحتاج **BLoC/Cubit** منفصل — لا `setState` للبيانات البعيدة
3. كل **route جديد** يُضاف في `routes.dart` و `app_routes.dart` معًا
4. كل **دالة في Service** تُعيد استثناء بدلًا من `null` عند الخطأ
5. لا **hardcoded strings** — استخدم ثوابت أو localization
6. **Typed models** للبيانات القادمة من الـ API — لا `Map<String, dynamic>` في طبقة العرض

---

*آخر تحديث: 2026-04-23 — مُراجَع بناءً على فحص الكود الفعلي لـ: payment_service.dart، dio_consumer.dart، user_service.dart، routes.dart، booking_request_screen.dart، payment_method_screen.dart، list_property_screen.dart، trips_screen.dart*
