# مهام حرجة — تطبيق Houseiana Mobile

> **التاريخ:** 2026-08-17
> **النطاق:** كود الـ Flutter بس (`lib/`). مشروع الويب **مش** مستخدم كمرجع ولا كدليل في أي بند هنا.
> **إزاي اتعملت:** 6 مراجعات متوازية على الكود (المصادقة / الحجز والدفع / طبقة الـ API / الكراشات وضياع البيانات / الأمان / شاشات المضيف)، طلعت 30 ملاحظة، عدّت 27 على مراجعة عكسية (agent تاني شغلته يكذّب الملاحظة من الكود)، وبعدها اتفلترت واتدمجت لـ 15 مهمة. أهم 8 بنود اتأكدت منها يدويًا سطر بسطر.
> **الفلتر:** أي حاجة مش بتكسر تدفق أساسي، أو بتغلط في فلوس، أو بتضيّع بيانات، أو كراش/تعليق دائم، أو ثغرة أمنية — مش موجودة هنا. مفيش تحسينات شكل ولا refactor.

---

## إزاي تستخدم الملف ده

- **القسم أ = ابعته للباك اند زي ما هو.** كل بند فيه الـ endpoint والـ payload اللي التطبيق بيبعته دلوقتي والمطلوب بالظبط.
- **القسم ب = شغلنا إحنا في التطبيق.**
- البنود اللي عليها علامة 🔗 محتاجة الاتنين مع بعض — الجزئين مفصولين جوه البند.

### أخطر 3 حاجات — لازم النهاردة

| # | المشكلة | مين |
|---|---|---|
| 1 | الدفع بيقول "تم" من غير ما يتأكد من السيرفر — الكارت المرفوض بيوصل لشاشة "تم تأكيد الحجز" | 🔗 الاتنين |
| 2 | مفتاحين Clerk **سريين live** متسجلين في الريبو وفي الـ git history | 🔗 الاتنين (الباك اند يبطّلهم فورًا) |
| 3 | أي حد بيعمل حساب جديد بيتطرد من الحساب بعد دقايق | الموبايل |

---

## جدول كل المهام

| كود | المهمة | الخطورة | مين |
|---|---|---|---|
| BE-1 / MB-1 | الدفع بيتحسب "ناجح" من غير تحقق من السيرفر | Blocker | 🔗 |
| BE-2 / MB-2 | مفاتيح Clerk السرية مسرّبة في الريبو | Critical | 🔗 |
| BE-3 / MB-3 | فشل الـ ratings API بيقتل صفحة العقار كلها | Critical | 🔗 |
| BE-4 / MB-4 | الشات والإشعارات بيكلموا Firestore من غير Firebase Auth | Critical | 🔗 |
| BE-5 | `GET /users/{id}` ممكن يرجّع PII أي مستخدم لأي حد مسجّل | Critical | الباك اند |
| BE-6 / MB-5 | التقييمات بتتبعت من غير `Authorization` خالص | High | 🔗 |
| MB-6 | حجز غير مدفوع مستحيل يتدفع — زرار "ادفع دلوقتي" مسدود | Blocker | الموبايل |
| MB-7 | التسجيل الجديد مش بيحفظ `clerk_session_id` → طرد من الحساب | Critical | الموبايل |
| MB-8 | نسيت كلمة السر مكسورة بالكامل — اللي بينسى بيتقفل بره للأبد | Critical | الموبايل |
| MB-9 | إيصال الدفع بيعرض الإجمالي بعلامة `$` وبالعربي مكتوب "دولار أمريكي" | Critical | الموبايل |
| MB-10 | العقارات بتتنشر بإحداثيات **بنجالور (الهند)** لو المضيف كتب العنوان يدوي | Critical | الموبايل |
| MB-11 | لو فشل استعلام التوفر، شاشة الحجز بتعرض إجمالي برسوم = صفر | High | الموبايل |
| MB-12 | تجديد التوكن بيكسر أي رفع ملفات (multipart) أول مرة التوكن يخلص | High | الموبايل |
| MB-13 | تعديل العقار بيضيّع أي كلام المضيف كتبه أثناء الحفظ | High | الموبايل |
| MB-14 | تقويم المضيف مش بيقبل الأرقام العربية (٢٥٠٠) — السعر والخصم مش بيتحفظوا | High | الموبايل |

---

# القسم أ — مهام الباك اند

> دي الحاجات اللي مينفعش نحلها من التطبيق لوحدنا. مكتوبة بالـ endpoint والـ payload الحالي والمطلوب.

---

## BE-1 🔗 — الدفع لازم يتأكد من السيرفر، مش من الـ URL

**الخطورة:** Blocker — دي أخطر واحدة في الملف كله.

### المشكلة
التطبيق دلوقتي بيقرر إن الفلوس "اتدفعت" من **شكل الـ URL** اللي بوابة الدفع بترجع عليه، مش من رد السيرفر.

- `external_payment_webview_screen.dart:79` — القيمة الافتراضية للنتيجة هي `{'success': true}`، يعني **لو محصلش أي تحقق، النتيجة "ناجح"**.
- `external_payment_webview_screen.dart:80-86` — التحقق من السيرفر بيحصل بس لو `provider == 'noqoody'`، أو `provider == 'paymob'` **و** الـ `intentionId` موجود. أي حالة تانية = مفيش أي call للسيرفر خالص.
- `external_payment_webview_screen.dart:63-75` — `_isSuccessUrl` بتتنفذ **قبل** `_isFailureUrl`، وبتشتغل بـ `url.contains('success')`. يعني redirect فيه `success=false` بيعدّي على إنه نجاح.
- `payment_method_screen.dart:286` — النتيجة بتتقارن بـ `result.contains('success')`، والقيمة الراجعة ممكن تكون `'failed:<رسالة الباك اند>'` — فأي رسالة فشل فيها كلمة `successful` بتروح على شاشة تأكيد الحجز.

### السيناريو
ضيف بيحجز وحدة instant-book ويدفع بالكارت (Paymob) → `POST /api/paymob/create-intention` يرجّع لينك الدفع لكن الـ intention id راجع برقم (numeric) أو تحت مفتاح تاني، فالتطبيق مش بيقراه → الكارت **يترفض** → Paymob يعمل redirect فيه `success=false` → التطبيق يقرا الـ substring ويقول نجاح → مفيش أي استعلام للسيرفر → المستخدم يشوف **"تم تأكيد الحجز"**.

### الأثر
الضيف متأكد إن الحجز مدفوع ومؤكد وهو مش مدفوع. يسافر يلاقي نفسه من غير حجز، وتقويم المضيف مقفول على حجز مش مدفوع. حالة الحجز وحالة الدفع مختلفين ومفيش أي مصالحة من ناحية السيرفر.

### المطلوب من الباك اند
1. **`POST /api/paymob/create-intention`**
   التطبيق بيبعت: `{"bookingId":"<id>", "phone":"<msisdn>"}`
   لازم يرجّع **دايمًا** الـ intention id كـ **string** تحت مفتاح ثابت:
   ```json
   { "paymobIntentionId": "<string>", "checkoutUrl": "<string>" }
   ```
   دلوقتي ممكن يرجّع لينك دفع من غير id صالح — وده اللي بيخلي التطبيق ياخد المسار غير المتحقق منه.

2. **`GET /api/paymob/payment-status/{intentionId}`**
   لازم يرجّع بالظبط المفاتيح دي (التطبيق بيقراها حرفيًا في `payment_service.dart:169-183`):
   ```json
   { "status": "SUCCESS|PAID|COMPLETED|PENDING|FAILED", "isPaid": true }
   ```

3. **`GET /api/noqoody/verify-payment/{bookingId}`**
   لازم يحط نتيجة الدفع في **حقل مخصص** (`paymentStatus` أو `isPaid`) جوه `data`.
   ممنوع الاعتماد على `success: true` بتاع الـ envelope — العميل بيقراها على إنها "اتدفع".

4. **مطلوب endpoint جديد — مرجع واحد لحالة الدفع مهما كانت البوابة:**
   ```
   GET /api/payments/status?bookingId={id}
   → { "bookingId": "...", "paymentStatus": "PAID|PENDING|FAILED|REFUNDED",
       "amount": 6300, "currency": "EGP", "providerTransactionId": "..." }
   ```
   يرجّع 200 بس لما يكون قرا السجل فعليًا.

5. **الأهم:** حالة `PAID` بتاعة الحجز لازم تتحدد من **webhooks سيرفر-لـ-سيرفر** من البوابات (Paymob / PayPal / Sadad / Noqoody)، مش من تفسير الموبايل للـ redirect.
   حاليًا `POST /api/paypal/capture-order/{orderId}` بيتنده **بس** من `paypal_webview_screen.dart:71-84` — يعني لو المستخدم قفل التطبيق بعد ما وافق على PayPal، الأوردر يفضل approved-but-uncaptured للأبد.

### الجزء بتاعنا (الموبايل) — MB
- `external_payment_webview_screen.dart:79` → الافتراضي يبقى `{'success': false, 'message': 'unverified'}` (fail closed).
- كل provider يعدّي على تحقق من السيرفر؛ لو الـ `intentionId` ناقص = فشل تحقق → `pending` مش `success`.
- `_isFailureUrl` تتنفذ قبل `_isSuccessUrl`، والمقارنة تبقى على `Uri.parse(url).queryParameters['success'] == 'true'` مش `contains`.
- `payment_method_screen.dart:286` → مقارنة بالمساواة `result == 'success'`.
- `payment_service.dart:295-301` → `_firstString` تقبل الأرقام كمان، و create-intention من غير id = فشل.

---

## BE-2 🔗 — مفتاحين Clerk سريين (sk_live) لازم يتبطّلوا فورًا

**الخطورة:** Critical — إجراء تشغيلي عاجل.

### المشكلة
`lib/core/config/clerk_config.dart` فيه مفتاحين **Clerk Backend API secret** بتوع الإنتاج مكتوبين نص صريح:

```
clerk_config.dart:37  sk_live_1v2twd9j6yO93Ial7eUUs30rg9A3eMU3v4KCZIdHXn
clerk_config.dart:38  sk_live_gia87Rsr3iMVlMAmVlbHVIW79TTQzrEbjULFRfHQsJ
```

الإنستانس: `pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ` / `https://clerk.houseiana.com`.
موجودين في الـ git history المدفوعة (commit `7756926`, remote `github.com/Houseiana/Houseiana-mobile.git`).

**تصحيح مهم في النطاق (مش بيقلل الخطورة):** السطور 1-56 كلها **متعلّقة كـ comment**، والكلاس الشغال بيخلي `secretKey` فاضي افتراضيًا (`clerk_config.dart:87-90`). يعني المفاتيح **مش متبنية جوه الـ APK/IPA**. التسريب في **الريبو والـ git history**، مش في الملف المنشور.

### الأثر
أي حد عنده صلاحية قراءة على الريبو — أو أي clone / fork / CI mirror / كوميت قديم — ياخد السطر ويشغّل:
```
curl -H "Authorization: Bearer sk_live_1v2twd9…" https://api.clerk.com/v1/users
```
ويقدر: يسحب كل المستخدمين بإيميلاتهم وتليفوناتهم، يعمل session لأي user id (`POST /v1/sessions`)، يغيّر باسورد أي حد (`PATCH /v1/users/{id}`)، يمسح حسابات.
وبما إن الباك اند بيصرّح على أساس Clerk session JWT — ده تجاوز كامل للمصادقة + تسريب بيانات شخصية جماعي.

### المطلوب من الباك اند / الـ Ops
1. **دلوقتي حالًا:** عمل rotate/revoke للمفتاحين من Clerk Dashboard (Configure → API Keys).
2. مراجعة Clerk API logs على المفتاحين دول للتأكد إنهم مااستخدموش من بره.
3. المفتاح الجديد يتخزن في environment الباك اند بس — ولا يوصل للموبايل نهائيًا.
4. لو لسه عايزين إلغاء الـ session عند تسجيل الخروج، الباك اند يعمل:
   ```
   POST /api/auth/logout   { "sessionId": "<id>" }
   Authorization: Bearer <Clerk JWT بتاع المستخدم>
   ```
   ويعمل الـ revoke من ناحية السيرفر — بدل `ClerkService.revokeSession()` اللي بيتنده من `auth_cubit.dart:442`.

### الجزء بتاعنا (الموبايل) — MB
- مسح البلوك المتعلّق `clerk_config.dart:1-56` بالكامل.
- شيل كل استخدامات `getBackendSecretKey()` من `clerk_service.dart` — `_backendDio` (26-33)، `_updateUserPassword` (554-578)، `getSession` (593-603)، `revokeSession` (606-613)، `getUserSessions` (616-623)، `getUser` (423-430) — علشان محدش يقدر يرجّع يحطها تاني.
- تنضيف الـ git history (git filter-repo / BFG) + force push، وإضافة gate على `sk_live_` في الـ CI.

---

## BE-3 🔗 — endpoint التقييمات لازم يرجّع 200 وليست فاضية، مش 404/500

**الخطورة:** Critical

### المشكلة
`PropertyDetailsCubit.loadRatings` بيعمل `emit(PropertyDetailsError(...))` من الـ catch بتاعه، وده **بيمسح** حالة `PropertyDetailsLoaded` اللي كانت نجحت خلاص. يعني فشل نداء ثانوي (المراجعات) بيحوّل صفحة العقار كلها لشاشة خطأ.

- `property_details_cubit.dart:60-62` — `loadRatings` بترجع من غير ما تعمل حاجة إلا لو الحالة أصلًا `PropertyDetailsLoaded` — يعني الـ catch بتاعها **دايمًا** بيدوس على حالة سليمة.
- `property_details_cubit.dart:81-83` — `catch (e) { emit(PropertyDetailsError(...)); }` من غير `isClosed` guard.
- `property_details_screen.dart:468-471` — `PropertyDetailsError` بيرسم شاشة خطأ full-screen، والشجرة المحمّلة (474+) مبتتبنيش.
- `property_service.dart:578-592` — `getRatingsPaginated` بيعمل rethrow لـ `ServerException` وميرجعش list فاضية.

### السيناريو
افتح أي عقار وقت ما `GET /api/ratings/property/{propertyId}?page=1&limit=10` يرجّع أي حاجة مش 2xx (500/404/gateway) أو يتخطى الـ 45 ثانية — سهل جدًا على نت ضعيف أو أثناء cold start بتاع الباك اند. الصفحة تظهر صح لحظة، وبعدين تقلب شاشة خطأ. السحب للتحديث يعيد نفس الحكاية.

### الأثر
الضيف مش قادر يشوف العقار خالص — لا صور، لا سعر، لا زرار احجز — بسبب نداء المراجعات بس. الحجز مستحيل على الوحدة دي، وكل العقارات في التطبيق بتتأثر في نفس اللحظة لما الـ endpoint ده يتعب.

### المطلوب من الباك اند
```
GET /api/ratings/property/{propertyId}?page=1&limit=10
```
لازم يرجّع **HTTP 200** مع list فاضية (أو `{"data": []}`) للعقار اللي لسه مفيهوش مراجعات — مش 404 ولا 500.

### الجزء بتاعنا (الموبايل) — MB
في `property_details_cubit.dart:81-83`:
```dart
catch (_) {
  if (!isClosed && state is PropertyDetailsLoaded) {
    emit((state as PropertyDetailsLoaded).copyWith(hasMoreRatings: false));
  }
}
```
البيانات الثانوية ممنوع تقدر تسقّط الحالة الأساسية.

---

## BE-4 🔗 — جسر Firebase مفقود: الشات والإشعارات شغالين من غير هوية

**الخطورة:** Critical — وده يا إما ميزة ميتة يا إما تسريب بيانات. محتاج رد من الباك اند علشان نعرف أنهي واحدة.

### المشكلة
التطبيق بيقرا ويكتب في مجموعات Firestore (`conversations`, `messages`, `notifications`) و`request.auth == null` — **مفيش ولا سطر واحد `FirebaseAuth` في `lib/` كلها**.

- `grep -rn "FirebaseAuth|signInWithCustomToken" lib/` → **صفر نتيجة**. `firebase_auth` معرّف في `pubspec.yaml:71` بس ومش مستخدم. `main.dart:36-42` بيعمل `Firebase.initializeApp` وخلاص.
- `firestore_chat_service.dart:263-269` — `watchConversations` بيستعلم بالـ Clerk id الخام (`guestId`/`hostId`/`participants`) من غير أي هوية Firebase.
- `firestore_chat_service.dart:307-318` — `onError: (Object _) { latest[index] = const []; emit(); }` — أي خطأ (بما فيه permission-denied) بيتحول لـ **list فاضية**. الـ `StreamController` عمره ما بيعمل `addError`.
- `conversations_cubit.dart:29-31` — فرع `ConversationsError` بقى كود ميت؛ الـ permission-denied بيظهر للمستخدم كـ "مفيش رسايل".
- `firestore_notification_service.dart:29-31,48-49,68-69` — نفس الحكاية على `notifications` بـ `userId` جاي من العميل.
- `end_points.dart:109` — `/api/chat/firebase-token` **معرّف في الكود ومتنداش ولا مرة**.
- مفيش `firestore.rules` في الريبو.

### الحالتين — والاتنين حرجين
- **(أ) لو الـ rules بتطلب auth:** كل الاستعلامات بتفشل permission-denied → الشاشة تقول "مفيش رسايل" للأبد، من غير خطأ ومن غير إعادة محاولة. الشات والإشعارات وكلّم-المضيف كلهم ميتين.
- **(ب) لو الـ rules بتسمح anonymous (وده الاحتمال الوحيد اللي الميزة شغالة بيه دلوقتي):** أي حد يسحب إعدادات Firebase من الـ APK (`lib/firebase_options.dart`, `android/app/google-services.json`) يقدر يقرا **كل** محادثات كل المستخدمين، ويكتب رسالة جوه أي محادثة — لأن `guestId`/`hostId`/`userId` مجرد قيم استعلام عادية والمهاجم بيتحكم فيها.

### المطلوب من الباك اند
1. **تنفيذ `GET /api/chat/firebase-token`** (الثابت محجوز في الكود من زمان ومتنداش أبدًا):
   - الطلب: `Authorization: Bearer <Clerk session JWT>` — من غير body ولا params.
   - الرد: `{ "token": "<Firebase custom token يكون الـ uid بتاعه = Clerk user id>" }`
   - `401` لو الـ Bearer مش صالح.
2. **إبلاغنا بالـ Firestore rules المنشورة حاليًا** على `conversations` و`conversations/{id}/messages` و`notifications`.
   لو بتسمح بوصول غير مصادَق دلوقتي — **دي حادثة تسريب بيانات شغالة** ولازم تتقفل مع نزول الـ token bridge في نفس الوقت.
   الـ rules المطلوبة بعد الإصلاح: `conversations/{id}` تتقرا/تتكتب بس لما `request.auth.uid in resource.data.participantIds` (+ `guestId`/`hostId`)، و`notifications/{id}` بس لما `request.auth.uid == resource.data.userId`.

### الجزء بتاعنا (الموبايل) — MB
- بعد كل تسجيل دخول ناجح (جنب تسجيل FCM token) نندي الـ endpoint ونعمل `FirebaseAuth.instance.signInWithCustomToken(token)` **قبل** أي وصول لـ Firestore، ونعيد السك عند التجديد، و`signOut()` في `AuthCubit.logout` / `FCMService.onLogout`.
- **ومستقل تمامًا عن رد الباك اند:** `firestore_chat_service.dart:314-317` لازم تبقى `controller.addError(e)` بدل `const []`. صندوق الرسايل ممنوع يقول "مفيش رسايل" على خطأ صلاحيات أو شبكة.

---

## BE-5 — `GET /users/{id}` ممكن يكون بيسرّب بيانات كل المستخدمين

**الخطورة:** Critical لو اتأكد. **محتاج رد/التقاط رد واحد علشان نحسمها.**

### المشكلة
شاشة بروفايل المضيف بتجيب **أي** user id عن طريق **نفس** الـ endpoint اللي بيخدم سجل حساب المستخدم نفسه:

- `user_service.dart:29` (بيانات المستخدم نفسه) و `user_service.dart:44` (`getPublicProfile` بـ id جاي من العميل) — **الاتنين** بينادوا `EndPoints.userById(userId)`.
- `end_points.dart:47` — `userById(String id) => '/users/$id'` — مفيش projection عام منفصل.
- `owner_profile_cubit.dart:15-31` — `getPublicProfile(hostId)`، والـ id ده أي ضيف مسجّل يوصله من صفحة العقار.
- `public_profile_model.dart:139-171` — الموديل بيفكّ: `email`, `phone`, `address`, `nationalID.idFrontPhoto`, `guestBookings`.
- `owner_profile_screen.dart:197` — بيعرض **عنوان** المستخدم اللي بتتفرج عليه في الهيدر.
- `owner_profile_screen.dart:162,371` — بيعرض **حجوزات** المستخدم ده كتبويب "الرحلات" كامل.

### الأثر لو اتأكد
أي مستخدم مسجّل (أو أي حد سحب توكن من جهازه هو) يقدر يلمّ إيميل وتليفون وعنوان البيت ولينك صورة الهوية وتاريخ الإقامات لكل مضيف وكل ضيف — بمجرد إنه يعدّي على الـ ids. تسريب بيانات شخصية واجب الإبلاغ عنه، وبيعرّض المضيفين للـ doxxing وسرقة الهوية.

### المطلوب من الباك اند
```
GET /users/{id}
Authorization: Bearer <توكن المُنادي>
```
1. **الأول:** التقاط رد واحد لـ `GET /users/{otherUserId}` بتوكن ضيف عادي، وإبلاغنا: هل الرد فيه `email` / `phone` / `address` / `nationalID` / `guestBookings` ولا لأ؟
2. **لو أيوه:** يتقسم التصريح — السجل الكامل يرجّع **بس** لما `{id}` = صاحب الـ JWT. وأي id تاني يرجّع projection مختصر:
   ```
   { id, firstName, profilePhoto, role, kycStatus (bool بس), createdAt, rating, properties, hostRatings }
   ```
   و`email`, `phone`, `address`, `nationalID`, `passport`, `guestBookings`, `hostBookings`, `preferredCurrency` تتشال **من ناحية السيرفر**.
3. **بديل مقبول:** إضافة `GET /users/{id}/public` بالـ projection المختصر، وإحنا نوجّه `UserService.getPublicProfile` عليه.

### الجزء بتاعنا (الموبايل)
أول ما الـ projection العام ينزل: توجيه `user_service.dart:44` عليه، وشيل حقول الـ PII من `PublicUserModel` (`public_profile_model.dart:101-109`) علشان متقدرش ترجع تظهر تاني.

---

## BE-6 🔗 — endpoint التقييم لازم يفرض المصادقة ومياخدش المستخدم من الـ body

**الخطورة:** High

### المشكلة
`RatingsService` و `HostCalendarService` بيبنوا Dio بتاعهم عن طريق `buildBackendDio()`، واللي **مربوط عليه `RetryInterceptor` بس** — من غير `AuthInterceptor` ولا `LangInterceptor`. يعني الطلبات دي بتخرج **من غير `Authorization` خالص**.

- `ratings_service.dart:10` — `RatingsService({Dio? dio}) : _dio = dio ?? buildBackendDio();`
- `backend_dio.dart:33-34` — `buildBackendDio` بيضيف `const RetryInterceptor()` وبس.
- `review_submission_cubit.dart:28` — بيعمل `RatingsService()` من غير dio، والخدمة **مش مسجّلة في الـ DI** أصلًا.
- `host_calendar_service.dart:9` + `properties_injection.dart:13` — نفس العيب بالظبط.

### المطلوب من الباك اند
```
POST /api/ratings/property-by-guest
body: { bookingId, propertyId, userId, rating, comment, categories? }
```
دلوقتي التطبيق بيبعت ده **من غير `Authorization` header**.
بعد ما نصلّح العميل — أكّدوا إن الـ endpoint **بيرفض** الطلب اللي مالوش Bearer، أو اللي صاحب التوكن فيه ≠ الـ `userId` اللي في الـ body. المفروض السيرفر يحدد المُقيِّم **من التوكن** مش من الـ body.
> لو الـ endpoint دلوقتي بيقبل الطلب من غير توكن — دي ثغرة: أي حد يقدر يكتب تقييمات باسم أي مستخدم.

### الجزء بتاعنا (الموبايل) — MB
- تسجيل الخدمتين في الـ DI بالـ Dio المصادَق: `sl.registerLazySingleton(() => RatingsService(dio: sl()))` ونفس الحاجة لـ `HostCalendarService` (`properties_injection.dart:13`).
- `ReviewSubmissionCubit` يجيب `sl<RatingsService>()` بدل `RatingsService()`.
- مسح الـ fallback `dio ?? buildBackendDio()` علشان محدش يسقّط المصادقة تاني من غير ما ياخد باله.

---

# القسم ب — مهام التطبيق (شغلنا)

---

## MB-6 — حجز غير مدفوع مستحيل يتدفع

**الخطورة:** Blocker | **المكان:** الحجز

### المشكلة
`Routes.paymentMethod` بيتفتح من **مكان واحد بس في التطبيق كله**: `booking_request_screen.dart:352`، جوه listener الـ `BookingCreated` **ومشروط بـ instant-book**. يعني أي حجز موجود ومش مدفوع مالوش أي طريق يوصّله لشاشة الدفع.

- `booking_request_screen.dart:346-352` — الـ push الوحيد، جوه `state is BookingCreated` ومشروط بـ `if (_isInstantBook)`. الفرع التاني (363-367) بيفتح dialog "تم إرسال الطلب" وبس.
- `trips_screen.dart:703-736` — كارت `isNeedToPay` بيرسم زرار `trips.payNow` بـ `onPressed: goToDetails` (سطر 724).
- `trips_screen.dart:354-357` — `goToDetails` بتفتح `Routes.tripDetails` وبس.
- `trip_details_screen.dart:327-402` — كل الأكشنز؛ الروت الوحيد المفتوح هو `Routes.reviewProperty`. **مفيش أي أكشن دفع.**
- `trips_screen.dart:850-856` — `NEEDTOPAY` (BookingStatus id = 4) حالة أساسية من الباك اند وليها تبويب مستقل، و`trip_model.dart:79,145` بيفك `paymentDueDate`.
- `payment_failed_screen.dart:259` — زرار "حاول تاني" = `Navigator.pop(context)` — بيرجّعك على شاشة الحجز من الأول.
- `booking_cubit.dart:16-74` — `createBooking` مفهوش أي حماية من التكرار.

### السيناريو
**المسار (أ):** ضيف يطلب حجز وحدة `instantBook:false` → الحجز يتعمل PENDING → المضيف يوافق → الحالة تبقى NEEDTOPAY بمهلة دفع → الضيف يفتح "الرحلات" يلاقي "الدفع مستحق قبل …" ويضغط "ادفع دلوقتي" → يروح على تفاصيل الرحلة اللي فيها بس: اكتب مراجعة / شارك الإيصال / إلغاء. **الحجز مستحيل يتدفع ويقع بانتهاء المهلة.**
**المسار (ب):** instant-book والكارت يترفض → شاشة فشل الدفع → "حاول تاني" ترجّعك لشاشة الحجز → تضغط "احجز" → **يتعمل حجز تاني** لنفس العقار ونفس التواريخ (أو يفشل فحص التوفر لأن الحجز الأول اليتيم ماسك التواريخ).

### الأثر
كل حجوزات الـ request-to-book على المنصة **مش قابلة للتحصيل من الموبايل**. الضيف بيتفرّج على مهلة دفع وزرار مبيعملش حاجة، وبعدين يخسر الحجز. وفي الـ instant book، كارت مرفوض واحد بيعلّق الحجز للأبد، والطريق الوحيد للإعادة بيعمل حجوزات مكررة بتقفل تقويم المضيف مرتين.

### الحل (مش محتاج أي تغيير في الباك اند)
كل endpoints بدء الدفع بتشتغل بالـ `bookingId` لوحده (`payment_service.dart:52-64,123-127,187-192,233-246`)، فالشاشة قابلة للاستئناف من غير أي حاجة جديدة:
1. `trips_screen.dart:722-736` — `onPressed` بتاع `isNeedToPay` يبقى:
   ```dart
   Navigator.pushNamed(context, Routes.paymentMethod, arguments: {
     'bookingId': trip.id, 'totalPrice': trip.totalPrice, 'property': <trip property map>,
   })
   ```
2. نفس الأكشن يتضاف في `trip_details_screen.dart:327-402` مشروط بـ `_booking!.paymentStatus != 'PAID'`.
3. `payment_failed_screen.dart:258-273` — "حاول تاني" تبقى `pushReplacementNamed(Routes.paymentMethod, arguments: {'bookingId': …})` بدل `pop`، علشان تعيد استخدام الحجز الموجود.
4. حماية من التكرار في `booking_cubit.dart#createBooking` — منع إعادة الإرسال طالما فيه حجز بنفس `propertyId` + التواريخ في حالة `BookingCreated`.

---

## MB-7 — كل حساب جديد بيتطرد من الجلسة بعد دقايق

**الخطورة:** Critical | **المكان:** المصادقة

### المشكلة
مسارات إنشاء الحساب بتحفظ الـ `userId` والـ JWT قصير العمر، لكن **مش بتحفظ الـ Clerk session id أبدًا**. وأول ما ييجي 401، `AuthInterceptor` مش قادر يجيب توكن جديد، فبيمسح الجلسة ويرجّع المستخدم على شاشة تسجيل الدخول.

- `clerk_service.dart:211-217` — الـ map الراجعة من `verifyEmailCode` فيها `success/data/message/userId/token` و**مفيش `sessionId`**.
- `clerk_service.dart:150-156` — فرع `complete` في `signUp` نفس الحكاية. بالمقارنة `signIn` (`clerk_service.dart:265-272`) **بيرجّع `sessionId` عادي**.
- `auth_cubit.dart:192-197` — `saveUser` بتتنده من غير أي `sessionId` في مسار تأكيد الإيميل.
- `user_session.dart:29` — `clerk_session_id` بيتكتب بس لو `sessionId != null`.
- `auth_interceptor.dart:47-51` — `if (sessionId == null || sessionId.isEmpty) { _logout(); return handler.next(err); }` — **التجديد بيتخطى بالكامل**.
- `auth_interceptor.dart:113-125` — `_logout()` بيمسح الكوكيز والجلسة والـ FCM ويعمل `pushNamedAndRemoveUntil(Routes.login, (r) => false)`.
- `sign_up_screen.dart:42-49` + `otp_verification_screen.dart:104-106` — مسار تأكيد الإيميل هو **مسار التسجيل الفعلي**.

### السيناريو
تثبيت جديد → تسجيل بإيميل وباسورد → إدخال كود الـ 6 أرقام → المستخدم يدخل عادي، والـ `clerk_user_id` و`auth_token` متخزنين بس من غير `clerk_session_id`. توكنات Clerk قصيرة العمر (موثّق في `clerk_service.dart:625-632`). بعد دقيقة، أي نداء مصادَق (سحب للتحديث في الرئيسية، فتح الرحلات، ضغط قلب المفضلة) يرجّع 401 → الـ interceptor ميلاقيش session id → يتخطى التجديد → يمسح كل حاجة ويشيل الـ navigation stack كله لحد شاشة الدخول.

### الأثر
كل مستخدم بيسجّل من التطبيق بيتطرد من حسابه بعد دقايق، في نص أي تدفق، من غير أي تفسير. واللي سجّل عشان يكمّل حجز بيخسر الشاشات كلها. الإصلاح الوحيد إنه يعمل login تاني — لأن `login()` هو المسار الوحيد اللي بيحفظ session id.

### الحل
1. `clerk_service.dart` — يتضاف في الـ map الراجعة من `verifyEmailCode` (211-217) وفرع `complete` في `signUp` (150-156):
   ```dart
   'sessionId': authData['sessionId'] ?? data?['created_session_id']?.toString() ?? '',
   ```
   (`_extractAuthData` بيحلّها أصلًا.)
2. `auth_cubit.dart:192-197` — تمرير `sessionId: sessionId.isNotEmpty ? sessionId : null` لـ `saveUser`، مع الإبقاء على fallback `saveAuthToken(sessionId)` زي `login()` بالظبط (`auth_cubit.dart:87-95`).
3. `auth_interceptor.dart:47-51` — غياب الـ session id لوحده **ممنوع** يعمل logout إجباري؛ يرجّع الـ 401 للمنادي بدل ما يهدّ الـ stack.

---

## MB-8 — "نسيت كلمة السر" مكسورة من 3 نقط مختلفة

**الخطورة:** Critical | **المكان:** المصادقة

### المشكلة
تدفق استرجاع كلمة السر مكسور في تلات أماكن مستقلة، فمفيش أي طريق شغال لاسترجاع الحساب في التطبيق:

1. **مفيش كود بيتبعت أصلًا** — `clerk_service.dart:441-496`: `createPasswordReset` بيعمل `POST /client/sign_ins {identifier}` وبس. **مفيش `prepare_first_factor` بـ `reset_password_email_code` في الملف كله**. ومع ذلك السطر 470-474 بيرجّع `success` ورسالة "Password reset code sent to your email"، والسطر 488-495 بيبلع أي `DioException` **ويرجّع `success: true` برضه**.
2. **الـ `signInId` بيتضيّع** — `auth_cubit.dart:322-324` بيرمي الـ signInId عند إطلاق `AuthPasswordResetEmailSent`؛ `auth_state.dart:63-70` الحالة شايلة `email` بس؛ `forgot_password_screen.dart:38-42` بتنقل بـ `{'email': ...}` بس؛ `app_routes.dart:41-46` بيبني `ResetPasswordScreen(email: args?['email'])`. فـ `reset_password_screen.dart:33,46-50` الـ `_signInId` **دايمًا null** → الطلب بيروح على `/client/sign_ins//attempt_first_factor`.
3. **كتابة الباسورد بتروح على endpoint ميت** — `clerk_service.dart:554-578`: `_updateUserPassword` بيعمل `PUT https://api.clerk.com/v1/users/{id}` على `_backendDio` اللي هيدره ثابت `Bearer ${ClerkConfig.getBackendSecretKey()}` = `'Bearer '` فاضي (`clerk_config.dart:87-90`) → **401**.
   نفس النداء الميت في `change_password_screen.dart:359` → `clerk_service.dart:582-587` لتغيير الباسورد للمستخدم المسجّل.

### السيناريو
دخول → "نسيت كلمة السر؟" → إدخال إيميل مسجّل حقيقي → إرسال. التطبيق يقول "تم إرسال كود لإيميلك" وينقلك للشاشة اللي بعدها، **ومفيش أي إيميل بيوصل**. تدخل أي كود وباسورد جديد → الطلب يروح `/client/sign_ins//attempt_first_factor` ويفشل؛ وحتى لو الـ id كان صح، كتابة الباسورد `PUT` غير مصادَق على `api.clerk.com`. نفس الطريق المسدود من البروفايل → تغيير كلمة السر.

### الأثر
أي حد نسي كلمة السر **مقفول بره Houseiana للأبد** — مفيش أي مسار استرجاع تاني في واجهة الموبايل. والمستخدم المسجّل كمان مش قادر يغيّر كلمة السر. كل محاولة بتنتهي بخطأ عام → تذاكر دعم وهجر حسابات.

### الحل (كله من التطبيق — مش محتاج secret key)
التدفق كله بيتعمل على Clerk **Frontend** API:
1. `createPasswordReset`: بعد `POST /client/sign_ins {identifier}` → `POST /client/sign_ins/{signInId}/prepare_first_factor {strategy: 'reset_password_email_code'}` وترجيع الـ `signInId`. ووقف رجوع `success:true` لما مفيش حاجة اتبعتت (488-495).
2. إضافة حقل `signInId` لـ `AuthPasswordResetEmailSent` (`auth_state.dart:63-70`) وتمريره: `auth_cubit.dart:324` → `forgot_password_screen.dart:41` → `app_routes.dart:44` → `ResetPasswordScreen`.
3. `resetPassword`: `POST /client/sign_ins/{signInId}/attempt_first_factor {strategy:'reset_password_email_code', code}` وبعدها `POST /client/sign_ins/{signInId}/reset_password {password, sign_out_of_other_sessions}` — بدل `_updateUserPassword`.
4. `change_password_screen`: يستخدم Clerk FAPI بالـ `__client` cookie المحفوظة.
5. مسح `_updateUserPassword` و`_backendDio` نهائيًا.

> **ملحوظة إعداد:** لازم استراتيجية `reset_password_email_code` تكون مفعّلة في Clerk Dashboard.

---

## MB-9 — الإيصال بيقول `$` والعربي بيقول "دولار أمريكي" على مبلغ بالجنيه

**الخطورة:** Critical | **المكان:** الدفع

### المشكلة
`BookingConfirmationScreen._displayTotal` بيلزق علامة دولار على `booking.totalPrice`، وبيحطها جوه قالب ترجمة **فيه عملة تانية مختلفة** — فبيطلع "EGP $6300" بالإنجليزي و **"دولار أمريكي $6300"** بالعربي، لحجز اتدفع فيه 6,300 جنيه.

- `booking_confirmation_screen.dart:83-86` — `return '\$${_booking!.totalPrice.toStringAsFixed(0)}';` — عملة الحجز متجاهلة تمامًا.
- `lib/i18n/translations/en.json:506` — `"totalPaidValue": "EGP {amount}"` → يطلع `EGP $6300`.
- `lib/i18n/translations/ar.json:506` — `"totalPaidValue": "دولار أمريكي {amount}"` → يطلع `دولار أمريكي $6300`.
- `booking_confirmation_screen.dart:198-201` و `338-347` — مكانين العرض (شيت الإيصال + بوكس "الإجمالي المدفوع").
- `booking_confirmation_screen.dart:95-115` — **نفس النص بيتنسخ للكليببورد** كإيصال قابل للمشاركة.
- `booking_model.dart:200-202` — `currencyLabel` (افتراضي `EGP`) موجود خلاص ومش مستخدم هنا.
- `trip_details_screen.dart:144` — نفس الـ `$` المكتوبة يدوي في إيصال الرحلة، بينما **نفس الملف** في السطر 208-212 بيستخدم `Money.format(..., currencyLabel)` صح.
- `payment_failed_screen.dart:68`, `payment_pending_screen.dart:101`, `payment_cancel_screen.dart:71` — الشاشات الشقيقة كلها عاملاها صح، فالنمط المقصود واضح.
- `host_dashboard_screen.dart:169-176` — نفس الـ `$` اليدوية على أرباح المضيف بالجنيه.

### الأثر
الشاشة الوحيدة اللي بتقول للضيف اتخصم منه كام — بتقول عملة غلط. وللمستخدم العربي بتسمّي عملة قيمتها حوالي **50 ضعف** اللي اتخصم فعلًا. وده بالظبط الاسكرين شوت اللي الضيوف بيبعتوه للبنك وللدعم → chargebacks ونزاعات على حجوزات متحصّلة صح. وبيناقض شاشة الحجز اللي المستخدم شافها من ثواني. ونفس العيب بيغلط في أرباح المضيفين.

### الحل
```dart
// booking_confirmation_screen.dart:83-86
return Money.format(_booking!.totalPrice, _booking!.currencyLabel);
```
(مع `import 'package:houseiana_mobile_app/core/utils/money.dart';` — زي `payment_failed_screen.dart:68`)
وبعدين شيل العملة المكررة من القالب: `"booking.totalPaidValue"` تبقى `"{amount}"` في **الملفين** `en.json:506` و `ar.json:506` — القيمة العربية لازم تفقد "دولار أمريكي" مهما كان.
ونفس الاستبدال في `trip_details_screen.dart:144` و `host_dashboard_screen.dart:173` (ومراجعة `pricing_setup_screen.dart:173,183`).

---

## MB-10 — العقارات بتتنشر بإحداثيات بنجالور (الهند)

**الخطورة:** Critical | **المكان:** المضيف

### المشكلة
`WizardData.toApiMap` بيرجع لثوابت حرفية `12.9388014` / `77.6104352` (بنجالور، الهند) كل ما يكون خط الطول/العرض `null`، وفحص الخطوة مش بيطلب دبوس على الخريطة أصلًا.

- `listing_wizard_state.dart:671-672`:
  ```dart
  map['address.latitude']  = latitude  ?? 12.9388014;
  map['address.longitude'] = longitude ?? 77.6104352;
  ```
  وبتتبعت من غير أي شرط جوه `includeStep(2)`.
- `listing_wizard_state.dart:600,617-628` — `includeStep(2)` بيشتغل كل ما المضيف يكمّل من خطوة الموقع، فالثوابت دي بتروح `POST /api/properties/draft`.
- `listing_wizard_cubit.dart:288-295` — `validateStepForContinue` حالة 1 بتفحص `address` و`city` بس؛ **مفيش أي شرط على الإحداثيات**.
- `step_03_location_screen.dart:731-805` — الفورم اليدوي عبارة عن dropdowns و TextFields (حي/عنوان/مبنى/دور/شقة/رمز بريدي) — **ولا واحد فيهم بيكتب lat/lng**.
- `step_03_location_screen.dart:334-346,477-484,852-873` — الكتّاب الوحيدين للإحداثيات هم: اختيار Places، الضغط على الخريطة، والضغط/السحب على خريطة التأكيد.
- `step_03_location_screen.dart:46,839-840,862-865` — خريطة التأكيد والدبوس الأحمر بيترسموا على `latitude ?? _currentLocation.latitude` و`_currentLocation = const LatLng(30.0444, 31.2357) // Cairo` — يعني **المضيف بيشوف دبوس فوق القاهرة** بينما الـ state فاضي وبنجالور هي اللي بتتبعت.

### السيناريو
المضيف → أضف عقار → خطوة الموقع → "إدخال يدوي" → يختار الدولة/المحافظة/الحي، يكتب العنوان، **من غير ما يلمس خريطة التأكيد** (اللي مورّياه دبوس معقول فوق القاهرة) → متابعة → يكمّل ويعمل نشر. العقار المنشور إحداثياته `12.9388014 / 77.6104352`.

### الأثر
خريطة العقار في صفحة التفاصيل بتشاور على بنجالور بالهند. وبما إن بحث الضيوف بيفلتر جغرافيًا بـ lat/lng + radiusKm، **الوحدة مش بتظهر في أي بحث بالخريطة أو بالمنطقة في مصر**. المضيف مش بيجيله ولا حجز ومش عارف ليه، وكل عقار متأثر لازم يترجع يتعدّل يدوي علشان البيانات المخزّنة تتصلّح.

### الحل
1. `listing_wizard_state.dart:671-672` — بطّل اختراع إحداثيات: ابعت `address.latitude`/`address.longitude` **بس** لما الاتنين مش null.
2. `listing_wizard_cubit.dart:288-295` — أضف فحص إحداثيات في حالة 1 علشان "متابعة" تتقفل لحد ما يبقى فيه دبوس.
3. `step_03_location_screen.dart` — زرّع في الـ cubit مركز الخريطة الحالي أول ما المضيف يفتح الفورم اليدوي (أو اكتب `loc` في `onCameraIdle`) علشان الدبوس الظاهر والقيمة المخزّنة ميختلفوش أبدًا.

> **ملحوظة للباك اند (اختيارية):** `POST /api/properties/draft` (multipart) بيستقبل دلوقتي `address.latitude=12.9388014, address.longitude=77.6104352`. لو ينفع يترفض حفظ عقار بإحداثيات بره نطاق الدولة المختارة، دي شبكة أمان كويسة — بس الإصلاح الأساسي عندنا.

---

## MB-11 — لو فشل استعلام التوفر، شاشة الحجز بتعرض إجمالي برسوم = صفر

**الخطورة:** High | **المكان:** الحجز

### المشكلة
`_loadAvailability()` بيبلع أي خطأ ويسيب `_availability` = null، وساعتها `_total` بيرجع لـ (سعر الليلة × الليالي) + رسوم بتتقرا من `_property['fees']` — وده **مفتاح مش موجود** في payload العقار. فالنتيجة إجمالي ناقص منه رسوم الخدمة والنظافة الحقيقية، وزرار "احجز" شغال عادي، والسيرفر بيسعّر الحجز من عنده.

- `booking_request_screen.dart:264-276` — الاستعلام ملفوف في `try { … } catch (_) { }` — من غير flag ولا إعادة محاولة ولا واجهة خطأ.
- `property_service.dart:595-612` — `getAvailability` بيعمل rethrow، فالـ timeout بيسيب `_availability` = null.
- `booking_request_screen.dart:139-144` — `_cleaningFee`/`_serviceFee`/`_total` بيرجعوا لـ payload العقار.
- `booking_request_screen.dart:77-83,112-118` — الاتنين بيقروا `_property['fees']['cleaning'|'service']` وبيرجّعوا **0** لما مش موجود.
- `availability_quote_rows.dart:11-12` و `price_details_section.dart:21-28` — ملاحظات الكود نفسه بتقول إن payload العقار بيقول `serviceFee: 0` حتى لما الاستعلام بيحاسب 2100.
- `booking_request_screen.dart:791-796,830,858-859` — صفوف الرسوم بصفر والإجمالي الغلط بيترسموا من غير أي شرط، و`canContinue = _checkIn != null && _checkOut != null && _guests >= 1` — يعني **"احجز" مش مربوط بنجاح الاستعلام**.
- `booking_cubit.dart:55-63` — `createBooking` مش بيبعت سعر؛ السيرفر هو اللي بيسعّر.

### السيناريو
افتح عقار، اختار تواريخ، اضغط احجز على نت ضعيف أو أثناء cold start (موثّق ~31 ثانية TTFB، وفيه `RetryInterceptor` مخصوص لده) فيحصل timeout لـ `GET /api/property-search/{id}/availability`. كارت السعر يعرض "رسوم النظافة 0 EGP" و"رسوم الخدمة 0 EGP" وإجمالي = الليلة × الليالي، **من غير أي خطأ**. تضغط احجز → `POST /booking-manager` من غير سعر → السيرفر يسعّر من عنده → المبلغ اللي بيروح للبوابة أعلى بكتير من اللي المستخدم شافه.

### الأثر
الضيف بيوافق على رقم وبيتخصم منه رقم أكبر — على إقامة ليلتين، ملاحظات الكود بتحط رسوم الخدمة المخفية عند 2,100 جنيه مقابل subtotal ~4,000. وبما إن الفشل صامت، لا الضيف ولا الدعم يقدر يفرّق بين شاشة مسعّرة غلط وشاشة صح.

### الحل
في `booking_request_screen.dart`:
1. حط flag `_availabilityFailed` / `_availabilityLoading` في الـ catch (274-276) بدل البلع.
2. اربط `canContinue` (830) بـ `_availTotalPrice != null` — "احجز" مقفول لحد ما ييجي تسعير حقيقي.
3. اعرض حالة إعادة محاولة بدل `_subtotal + 0 + 0` لما الاستعلام يفشل.
4. امسح `_cleaningFeeFromProperty()` / `_serviceFeeFromProperty()` (77-83, 112-118) — ملاحظات الكود نفسها بتقول إن رسوم payload العقار **مش** الرسوم المحصّلة، وإجمالي مفبرك أسوأ من إننا مانعرضش حاجة.

> مصدر الرسوم الوحيد هو: `GET /api/property-search/{propertyId}/availability?checkin={iso}&checkout={iso}` → `{isAvailable, subtotal (مخصوم أصلًا), discount, cleaningFee, serviceFee, totalPrice, nights}`.

---

## MB-12 — تجديد التوكن بيكسر أي رفع ملفات أول مرة التوكن يخلص

**الخطورة:** High | **المكان:** المضيف / البروفايل

### المشكلة
`AuthInterceptor._retry` بيعيد إرسال `requestOptions.data` زي ما هي؛ ولما الداتا دي `FormData` كانت اتقفلت (finalized) في المحاولة الأولى، dio 5.9.1 بيرمي `StateError`، والـ interceptor بيبلعه ويطلّع الـ 401 الأصلي. يعني **كل طلب multipart بيصادف توكن منتهي بيفشل مرة**.

- `auth_interceptor.dart:88-111` — `_retry` بيمرّر `data: requestOptions.data` على Dio عارية من غير أي حماية للـ body اللي بيتقري مرة واحدة.
- `auth_interceptor.dart:62-72` — التوكن الجديد **بيتحفظ الأول**، وبعدين الـ `StateError` بيقع في `catch (_) { handler.next(err); }`.
- `retry_interceptor.dart:89-91` — الـ interceptor الشقيق اللي على **نفس** الـ Dio فيه بالظبط حماية الـ FormData الناقصة هنا.
- dio-5.9.1 `dio_mixin.dart:642-646` → `form_data.dart:165-172` — تاني `finalize()` بيرمي `StateError('The FormData has already been finalized')`.
- `host_service.dart:37,100` — `FormData.fromMap` لـ `createListing`/`saveDraft`.
- `dio_consumer.dart:75-81` + `user_service.dart:184-190` — مسار تحديث البروفايل بـ `formDataIsEnabled`.

### السيناريو
سجّل دخول، افتح wizard إضافة عقار، خد دقيقة في خطوة لحد ما التوكن يخلص، بعدين اضغط "متابعة". `POST /api/properties/draft` يرجّع 401 → الـ interceptor يجيب توكن جديد ويحفظه → يعيد إرسال الـ multipart → dio يرمي `StateError` → المضيف يشوف "فشل حفظ المسودة" والخطوة متتقدمش. الضغط تاني بينجح لأن التوكن الجديد اتحفظ خلاص. نفس الدبل-كليك مطلوب في النشر، وحفظ البروفايل، ورفع الباسبور، ورفع البطاقة.

### الأثر
المضيفين بيقابلوا فشل غير مفهوم في كل خطوة من خطوات الـ wizard تقريبًا بعد أي فترة خمول، ولازم يعيدوا كل واحدة. والضيوف نفس الحاجة في تعديل البروفايل ورفع مستندات الـ KYC — وهناك بتبان كإن الرفع اترفض.

### الحل
في `auth_interceptor.dart` — نفس حماية `retry_interceptor.dart:89-91`: لو `err.requestOptions.data is FormData` **متعملش** `_retry`؛ اجيب واحفظ التوكن الجديد (علشان محاولة المنادي الجاية تبقى مصادَقة) وبعدين `handler.next(err)`.
وخلي `_retry` تمسك الأخطاء اللي مش `DioException` صراحةً بدل `catch (_)`.
**والأحسن:** تجديد استباقي للتوكن قبل أي رفع multipart (`HostService.saveDraft/createListing/modifyProperty`, `DioConsumer.post` بـ `formDataIsEnabled`) بدل الاعتماد على دورة الـ 401.

---

## MB-13 — تعديل العقار بيضيّع أي كلام اتكتب أثناء الحفظ

**الخطورة:** High | **المكان:** المضيف

### المشكلة
`_modifyListing` بيبني الـ payload من `state.data` **قبل** النداء، لكن بيحرّك خط أساس الـ diff لـ `state.data` المقروءة **بعد** النداء. يعني أي حاجة المضيف كتبها أثناء الطلب بتتحسب "اتحفظت خلاص" ومش هتتبعت في أي حفظ بعد كده.

- `listing_wizard_cubit.dart:538-542` — `payload = state.data.toModifyMap(..., original: original)` بتتبني قبل الـ await.
- `listing_wizard_cubit.dart:564` — `await _hostService.modifyProperty(payload)`.
- `listing_wizard_cubit.dart:567-571` — بيعمل emit بـ `originalData: state.data` — **بيقرا الـ state تاني بعد الـ await**.
- `listing_wizard_state.dart:832-859` — `toModifyMap` بتطلّع بس المفاتيح اللي قيمتها مختلفة عن خط الأساس، فأي حاجة اتلمّت جوه الأساس **مستحيل تتبعت تاني**.
- `step_07_title_screen.dart:112,124` — حقول النص بتنده `cubit.updateStepData({...})` مع **كل حرف**.
- `property_wizard_screen.dart:163-183,241,284,312` — أزرار الفوتر بس هي اللي بتتقفل أثناء الانشغال؛ صفحات الـ PageView فاضلة موجودة وقابلة للكتابة.
- `backend_dio.dart:14` — الـ 45 ثانية receive timeout بتوسّع نافذة الـ race.

### السيناريو
افتح عقار منشور من الاستضافة → العقارات → تعديل، روح لخطوة العنوان/الوصف، اضغط "متابعة" **وفضل تكتب في الوصف والدائرة بتلف** (سهل جدًا في أول طلب في الجلسة، ~31 ثانية cold start). لما الطلب يرجع، الحروف الزيادة موجودة على الشاشة وفي الـ state لكن **عمرها ما اترفعت**. تضغط متابعة تاني أو "تعديل العقار" → بيتبعت diff فاضي → السيرفر يفضل ماسك الوصف القديم للأبد.

### الأثر
تعديلات المضيف بتبان مقبولة — مفيش خطأ، النص لسه على الشاشة، الـ wizard اتقدّم — لكنها **ضاعت نهائيًا على السيرفر**، ومفيش حفظ بعد كده يقدر يرجّعها لأن الـ wizard مقتنع إنها اتخزنت.

### الحل
في `listing_wizard_cubit.dart#_modifyListing`: خد snapshot في سطر بناء الـ payload:
```dart
final sent = state.data;   // سطر 538
...
emit(state.copyWith(originalData: sent));   // سطر 570 — بدل state.data
```
واختياريًا: تعطيل مدخلات الخطوة (أو إعادة حساب الـ diff بعد الـ emit) طول ما `isSavingDraft` شغال.

---

## MB-14 — تقويم المضيف مش بيقبل الأرقام العربية

**الخطورة:** High | **المكان:** المضيف

### المشكلة
حقول السعر وأساس الخصم ونسبة الخصم في التقويم بتفكّ الإدخال بـ `double.tryParse` / `int.tryParse` على النص الخام — واللي بيرجّع `null` للأرقام العربية (٢٥٠٠). القيمة بتقع على 0 وزرار الحفظ بيتقفل **من غير أي رسالة**.

- `host_calendar_screen.dart:966-967` — `_price = double.tryParse(v.trim()) ?? 0` من غير أي input formatter.
- `host_calendar_screen.dart:982-984` — `onPressed: (_price ?? 0) <= 0 ? null : …` — الزرار بيموت في صمت.
- `host_calendar_screen.dart:1051-1052,1091-1094` — نفس الـ parse الخام لأساس الخصم والنسبة.
- `host_calendar_screen.dart:1011,1139-1142` — `canApply = _discountPercent > 0 && base > 0` بيتحكم في زرار "تطبيق".
- `lib/core/utils/number_input.dart:14-51` — `WesternDigitsInputFormatter` و`toWesternDigits()` **موجودين خلاص**، والمستهلك الوحيد ليهم في `lib/` هو `step_11_pricing_screen.dart`.
- `host_calendar_screen.dart:582-586,929-932,1235-1243` — حقل السعر متزرّع مسبقًا وفيه أسهم ±10 (حل التفاف مؤقت)؛ حقل نسبة الخصم **مالوش لا ده ولا ده**.

### السيناريو
خلّي لغة الجهاز عربي علشان الكيبورد الرقمي يطلّع ٠-٩. المضيف → العقارات → التقويم → اختار مدى تواريخ → "تحديد سعر" → اكتب ٢٥٠٠. الحقل بيعرض ٢٥٠٠ لكن "حفظ السعر" فاضل رمادي ومفيش أي حاجة تتبعت. وفي تبويب الخصم، لا سعر ما قبل الخصم ولا النسبة ينفع يتكتبوا، ومفيش أسهم بديلة.

### الأثر
المضيف اللي كيبورده عربي **مش قادر يحدد أسعار موسمية أو خاصة، ولا يطبّق خصم على مدى تواريخ خالص** — أهم أداة لإدارة الإيراد في التقويم معطلة، ومن غير أي رسالة تفسّر ليه الزرار ميت.

### الحل
أضف `inputFormatters: const [WesternDigitsInputFormatter()]` للتلات TextFields في `host_calendar_screen.dart:935` و `:1022` و `:1065`، وافكّ القيم بـ `double.tryParse(v.trim().toWesternDigits())` / `int.tryParse(v.trim().toWesternDigits())` (مع `import 'package:houseiana_mobile_app/core/utils/number_input.dart';`) — بالظبط زي `step_11_pricing_screen.dart`.

---

## ملحق — أرقام المراجعة

| | |
|---|---|
| ملفات Dart متفحّصة | 292 (`lib/`) |
| ملاحظات مرفوعة | 30 |
| عدّت المراجعة العكسية | 27 |
| بعد الدمج والفلترة النهائية | **15 مهمة** |
| اتأكدت يدويًا سطر بسطر | 8 بنود (BE-1, BE-2, BE-3, BE-6, MB-6, MB-7, MB-9, MB-10) |
| مصدر الأدلة | كود `lib/` فقط — مشروع الويب مستبعد |
