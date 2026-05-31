# قائمة مهام إصلاح جاهزية النشر لتطبيق Flutter

> الهدف: تحويل تطبيق Flutter إلى نسخة مكتملة وقابلة للنشر بنسبة 100% من ناحية الظهور، الربط، قابلية الاستخدام، وتطابق تجربة المنتج مع الويب قدر الإمكان.
>
> القاعدة الصارمة: كل الإصلاحات داخل مشروع Flutter فقط. مشروع الويب read-only ومصدر الحقيقة ولا يتم تعديله.

## المرحلة 0: تثبيت خط الأساس والتحقق من البناء

### 0.1 تشغيل أدوات التحقق الأساسية

- الاعتمادات: لا يوجد.
- الملفات المتأثرة: لا يوجد تعديل متوقع.
- خطوات التنفيذ:
  - تشغيل `flutter --version`.
  - تشغيل `flutter pub get`.
  - تشغيل `flutter analyze`.
  - تشغيل `flutter test`.
  - تشغيل build debug أو تشغيل على emulator عند توفره.
- الحالات الطرفية:
  - أدوات Flutter قد تعلق أو تفشل بسبب بيئة محلية.
  - dependencies قد تحتاج إصلاح قبل الوصول للكود.
- تعريف الإنجاز:
  - يوجد سجل واضح للأخطاء الحالية.
  - لا يبدأ إصلاح وظيفي كبير قبل معرفة build blockers.

### 0.2 إصلاح compile blockers المؤكدة

- الاعتمادات: 0.1.
- الملفات المتأثرة:
  - `lib/features/messages/presentation/screens/conversations_screen.dart`
  - `lib/core/services/user_service.dart`
  - `lib/core/services/chat_service.dart`
  - `lib/core/network/api/auth_interceptor.dart`
- خطوات التنفيذ:
  - إصلاح استدعاء `_userService.getConversations` لأنه غير موجود.
  - إما نقل الشاشة لاستخدام `ChatService.getConversations` أو إضافة method صحيحة في service مناسب بدون تكرار سيئ.
  - التأكد من import صحيح لـ `GlobalKey<NavigatorState>` في `auth_interceptor.dart`.
  - إعادة تشغيل `flutter analyze`.
- الحالات الطرفية:
  - وجود أكثر من نظام رسائل (`messages` و`chat`) قد يسبب تضارب.
  - إصلاح سريع للcompile لا يعني أن flow الرسائل جاهز وظيفيا.
- تعريف الإنجاز:
  - `flutter analyze` لا يحتوي أخطاء compile لهذه الملفات.
  - شاشة المحادثات لا تستدعي methods غير موجودة.

### 0.3 إنشاء قائمة smoke test أساسية

- الاعتمادات: 0.1 و0.2.
- الملفات المتأثرة:
  - `test/`
  - وربما `integration_test/` إن كان مفعلا.
- خطوات التنفيذ:
  - إضافة smoke tests بسيطة للتأكد من app boot.
  - اختبار route generation لأهم routes.
  - اختبار أن bottom nav يفتح بدون crash.
- الحالات الطرفية:
  - بعض services تحتاج mocks لتجنب network calls.
- تعريف الإنجاز:
  - يوجد test يمنع رجوع أخطاء route/build الأساسية.

## المرحلة 1: إصلاح الملاحة والوصول للميزات

### 1.1 توحيد route registry وإزالة dead routes

- الاعتمادات: المرحلة 0.
- الملفات المتأثرة:
  - `lib/core/constants/routes/routes.dart`
  - `lib/core/constants/routes/app_routes.dart`
  - أي شاشة تستدعي routes غير مسجلة.
- خطوات التنفيذ:
  - مطابقة كل constant في `Routes` مع route مسجل أو حذف استخدامه من UI.
  - تسجيل routes المستخدمة فعلا مثل `Routes.properties` أو تغيير الاستدعاءات للمسار الصحيح.
  - مراجعة constants غير المسجلة: `dateSelection`, `guestSelection`, `amenities`, `reviews`, `locationMap`, `profile`, `properties`, `home`.
- الحالات الطرفية:
  - بعض routes قد تكون مخططة فقط وليست مطلوبة الآن.
  - لا تجعل route يعمل إلى شاشة placeholder فقط لإسكات الخطأ.
- تعريف الإنجاز:
  - لا يوجد navigation إلى route غير مسجل.
  - أي route ظاهر في UI يفتح شاشة مفيدة.

### 1.2 إصلاح launch flow

- الاعتمادات: 1.1.
- الملفات المتأثرة:
  - `lib/app.dart`
  - `lib/features/splash/presentation/screens/splash_screen.dart`
  - `lib/core/services/user_session.dart`
- خطوات التنفيذ:
  - تحديد هل البداية الصحيحة هي splash أو bottom nav.
  - إذا splash مطلوب، اجعله initial route ويتحقق من session بشكل واضح.
  - إذا bottom nav هو المقصود، أزل reliance على splash كجزء release flow.
- الحالات الطرفية:
  - مستخدم مسجل سابقا.
  - مستخدم جديد.
  - فشل تحميل session.
- تعريف الإنجاز:
  - بداية التطبيق واضحة ومستقرة.
  - لا توجد شاشة مهمة غير مستخدمة في launch flow بدون سبب.

### 1.3 توحيد تمرير arguments بين القوائم وتفاصيل العقار

- الاعتمادات: 1.1.
- الملفات المتأثرة:
  - `lib/features/properties/presentation/screens/properties_screen.dart`
  - `lib/features/properties/presentation/screens/search_properties_screen.dart`
  - `lib/features/home/presentation/screens/home_screen.dart`
  - `lib/features/favorites/presentation/screens/favorites_screen.dart`
  - `lib/features/property_details/presentation/screens/property_details_screen.dart`
  - `lib/core/constants/routes/app_routes.dart`
- خطوات التنفيذ:
  - اعتماد شكل واحد لفتح التفاصيل: `{'propertyId': id, 'property': property}`.
  - إصلاح `PropertiesScreen` الذي يمرر `arguments: p`.
  - مراجعة كل `Navigator.pushNamed(... Routes.propertyDetails ...)`.
  - إضافة fallback داخل route/parser إذا وصل model خام، لكن لا تعتمد عليه كحل رئيسي.
- الحالات الطرفية:
  - عقار بدون `id`.
  - عقار id باسم `_id` بدلا من `id`.
  - بيانات ناقصة من API.
- تعريف الإنجاز:
  - الضغط على أي بطاقة عقار من Home/Search/Favorites/Recommendations يفتح تفاصيل صحيحة.
  - لا توجد شاشة تفاصيل فارغة بسبب missing id.

## المرحلة 2: البحث والاكتشاف والتصفح

### 2.1 توحيد مصدر البحث حول API حقيقي مطابق للويب

- الاعتمادات: المرحلة 1.
- الملفات المتأثرة:
  - `lib/core/services/property_service.dart`
  - `lib/features/properties/cubit/search_cubit.dart`
  - `lib/features/properties/presentation/screens/search_properties_screen.dart`
  - `lib/features/properties/presentation/screens/properties_screen.dart`
  - `lib/features/search/presentation/screens/search_modal_screen.dart`
- خطوات التنفيذ:
  - مراجعة web API المستخدم في الويب: `publicSearchFilter`.
  - جعل Flutter يمرر نفس الفلاتر الممكنة: location، price، bedrooms، beds، bathrooms، minRating، amenities، guests، page، limit.
  - إزالة ازدواجية behavior بين `PropertiesScreen` و`SearchPropertiesScreen` أو جعل الاثنين يستخدمان نفس cubit/search service.
- الحالات الطرفية:
  - location فارغة.
  - فلاتر كثيرة بدون نتائج.
  - pagination مع تغيير الفلاتر.
- تعريف الإنجاز:
  - نتائج Flutter تتغير فعليا عند تغيير الفلاتر.
  - لا توجد شاشة بحث رئيسية تعتمد على list عامة فقط.

### 2.2 إصلاح Advanced Filters في تبويب Search

- الاعتمادات: 2.1.
- الملفات المتأثرة:
  - `lib/features/properties/presentation/screens/properties_screen.dart`
  - `lib/features/properties/presentation/screens/advanced_filters_screen.dart`
- خطوات التنفيذ:
  - استقبال result من `AdvancedFiltersScreen`.
  - حفظ الفلاتر في state.
  - إعادة طلب النتائج بالفلاتر بدلا من `_loadData()` العام.
  - عرض chips أو summary للفلاتر النشطة.
- الحالات الطرفية:
  - المستخدم يلغي الفلتر.
  - reset filters.
  - amenities lookup fail.
- تعريف الإنجاز:
  - أي فلتر يختاره المستخدم يظهر أثره في النتائج.
  - يمكن مسح الفلاتر والعودة للنتائج العامة.

### 2.3 تحسين Discover/Explore visibility

- الاعتمادات: 2.1 و2.2.
- الملفات المتأثرة:
  - `lib/features/bottom_nav/presentation/screens/bottom_nav_screen.dart`
  - `lib/features/discover/presentation/screens/discover_screen.dart`
  - `lib/features/properties/presentation/screens/properties_screen.dart`
- خطوات التنفيذ:
  - تحديد هل تبويب Search هو Discover الفعلي.
  - دمج أفضل عناصر `DiscoverScreen` داخل تبويب Search أو جعل Discover route ظاهر من Home.
  - عدم ترك Discover كشاشة جميلة لكنها مخفية.
- الحالات الطرفية:
  - عدم تكرار شاشتين بنفس الوظيفة.
  - الحفاظ على أداء القائمة.
- تعريف الإنجاز:
  - تجربة discovery المهمة مرئية من الملاحة الأساسية.
  - المستخدم يستطيع البحث والتصفح والتصفية من مكان واضح.

### 2.4 استبدال الخريطة الشكلية بتجربة مفيدة أو إخفاؤها

- الاعتمادات: 2.1.
- الملفات المتأثرة:
  - `lib/features/properties/presentation/screens/properties_screen.dart`
  - وربما package config إذا تم استخدام maps حقيقي.
- خطوات التنفيذ:
  - إما ربط map حقيقية بإحداثيات العقارات.
  - أو تحويل map toggle إلى list-only إلى حين الجاهزية.
  - لا تعرض markers شكلية توحي بوظيفة غير موجودة.
- الحالات الطرفية:
  - عقارات بلا إحداثيات.
  - صلاحيات location.
  - API map keys.
- تعريف الإنجاز:
  - لا يوجد UI يوحي بخريطة تفاعلية إذا لم تكن كذلك.

## المرحلة 3: تفاصيل العقار

### 3.1 إصلاح تحميل تفاصيل العقار والتقييمات والتوفر

- الاعتمادات: 1.3.
- الملفات المتأثرة:
  - `lib/features/property_details/presentation/screens/property_details_screen.dart`
  - `lib/features/property_details/presentation/cubit/property_details_cubit.dart`
  - `lib/core/services/property_service.dart`
  - `lib/core/services/ratings_service.dart`
- خطوات التنفيذ:
  - جعل تحميل details ينتظر اكتمال property قبل ratings/availability.
  - أو تعديل cubit ليقبل تحميل availability/ratings بشكل مستقل مع propertyId.
  - إضافة state واضح للتوفر والتقييمات.
- الحالات الطرفية:
  - فشل availability مع نجاح details.
  - فشل ratings مع نجاح details.
  - propertyId غير صالح.
- تعريف الإنجاز:
  - التفاصيل تعرض العقار والتقييمات والتوفر عند الإمكان.
  - فشل جزء لا يجعل الشاشة فارغة بالكامل.

### 3.2 مطابقة محتوى تفاصيل العقار مع intent الويب

- الاعتمادات: 3.1.
- الملفات المتأثرة:
  - `lib/features/property_details/presentation/screens/property_details_screen.dart`
  - `lib/shared/widgets/cards/property_card_v2.dart`
- خطوات التنفيذ:
  - مراجعة blocks الأساسية في الويب: images، amenities، rules، location، reviews، host، cancellation، booking card.
  - التأكد أن Flutter يعرض أهم blocks أو fallback واضح.
  - ترتيب action hierarchy بحيث زر الحجز واضح وثابت.
- الحالات الطرفية:
  - صور ناقصة.
  - مرافق فارغة.
  - تقييمات فارغة.
- تعريف الإنجاز:
  - صفحة التفاصيل مقنعة ومكتملة بما يكفي لاتخاذ قرار حجز.

### 3.3 توحيد contact host من التفاصيل

- الاعتمادات: 3.1 والمرحلة 8 لاحقا.
- الملفات المتأثرة:
  - `lib/features/property_details/presentation/screens/property_details_screen.dart`
  - `lib/features/messages/presentation/screens/contact_host_screen.dart`
  - `lib/features/chat/presentation/cubit/chat_cubit.dart`
- خطوات التنفيذ:
  - تمرير `propertyId`, `hostId`, `propertyTitle`, `hostName` بشكل مضمون.
  - auth-gate واضح قبل فتح المراسلة.
  - عدم استخدام fallback وهمي إلا كعرض loading/error.
- الحالات الطرفية:
  - عقار بدون hostId.
  - مستخدم غير مسجل.
- تعريف الإنجاز:
  - زر تواصل مع المضيف يفتح محادثة حقيقية أو رسالة خطأ مفهومة.

## المرحلة 4: الحجز

### 4.1 مطابقة booking request مع تدفق الويب

- الاعتمادات: المرحلة 3.
- الملفات المتأثرة:
  - `lib/features/booking/presentation/screens/booking_request_screen.dart`
  - `lib/features/booking/presentation/cubit/booking_cubit.dart`
  - `lib/core/services/user_service.dart`
  - `lib/core/services/property_service.dart`
- خطوات التنفيذ:
  - جعل الحجز يبدأ من propertyId/checkIn/checkOut/guests مثل الويب.
  - جلب availability/pricing من backend قبل إنشاء booking.
  - عدم الاعتماد على حساب محلي فقط للسعر.
  - إضافة guest details المطلوبة إذا backend يحتاجها.
- الحالات الطرفية:
  - تواريخ محجوزة.
  - minimum nights.
  - guests أكبر من capacity.
  - سعر تغير قبل الدفع.
- تعريف الإنجاز:
  - لا يمكن إنشاء حجز بتواريخ غير متاحة.
  - السعر النهائي من backend وليس تقديرا محليا فقط.

### 4.2 إصلاح DTO إنشاء الحجز

- الاعتمادات: 4.1.
- الملفات المتأثرة:
  - `lib/core/services/user_service.dart`
  - `lib/features/booking/presentation/cubit/booking_cubit.dart`
  - models المرتبطة بالحجز.
- خطوات التنفيذ:
  - مقارنة body المرسل من Flutter مع body المستخدم في web booking service.
  - توحيد أسماء الحقول المطلوبة.
  - تضمين userId/session عند الحاجة.
- الحالات الطرفية:
  - backend يقبل `property` أو `propertyId`.
  - guests object vs number.
- تعريف الإنجاز:
  - API إنشاء الحجز ينجح من Flutter بنفس contract الويب.

### 4.3 تحسين حالات الحجز المرئية

- الاعتمادات: 4.1 و4.2.
- الملفات المتأثرة:
  - `lib/features/booking/presentation/screens/booking_request_screen.dart`
  - `lib/features/booking/presentation/screens/booking_confirmation_screen.dart`
  - `lib/features/booking/presentation/screens/booking_details_screen.dart`
- خطوات التنفيذ:
  - عرض loading واضح عند التحقق.
  - عرض price breakdown.
  - عرض error عند unavailable dates.
  - عرض success مع route واضح للدفع أو تفاصيل الحجز.
- الحالات الطرفية:
  - network timeout.
  - booking created لكن payment screen فشل.
- تعريف الإنجاز:
  - المستخدم يفهم كل خطوة ولا يعلق في شاشة غير واضحة.

## المرحلة 5: الدفع

### 5.1 استبدال مسار الدفع ليطابق الويب

- الاعتمادات: المرحلة 4.
- الملفات المتأثرة:
  - `lib/features/booking/presentation/screens/payment_method_screen.dart`
  - `lib/core/services/payment_service.dart`
  - `lib/core/services/stripe_payment_service.dart`
  - `lib/core/services/paypal_payment_service.dart`
  - `lib/features/booking/presentation/screens/paypal_webview_screen.dart`
  - `lib/features/booking/presentation/screens/sadad_webview_screen.dart`
  - أي config متعلق بالدفع في `lib/core/config/app_config.dart`
- خطوات التنفيذ:
  - اعتماد نفس طرق الويب: Paymob للبطاقة، PayPal، Sadad، Noqoody.
  - عدم استخدام Stripe كبديل release إذا لم يكن ضمن flow الويب الحالي.
  - إضافة endpoints/service methods المطابقة لمسارات الويب backend.
  - تحديث UI لعرض طرق الدفع الفعلية فقط.
- الحالات الطرفية:
  - provider غير متاح.
  - payment link لا يرجع.
  - redirect/callback غير مكتمل.
- تعريف الإنجاز:
  - طرق الدفع في Flutter تطابق طرق الويب وظيفيا.
  - لا توجد طريقة دفع ظاهرة لكنها غير مدعومة.

### 5.2 إصلاح PayPal lifecycle

- الاعتمادات: 5.1.
- الملفات المتأثرة:
  - `lib/core/services/payment_service.dart`
  - `lib/features/booking/presentation/screens/paypal_webview_screen.dart`
  - `lib/features/booking/presentation/screens/payment_method_screen.dart`
- خطوات التنفيذ:
  - حفظ orderId من create.
  - تمرير userId الحقيقي عند capture إذا backend يحتاجه.
  - التعامل مع cancel/success/failure URLs.
- الحالات الطرفية:
  - المستخدم يغلق webview.
  - PayPal approval بدون capture.
- تعريف الإنجاز:
  - PayPal payment يصل إلى حالة success/failure مؤكدة.

### 5.3 إصلاح Sadad lifecycle

- الاعتمادات: 5.1.
- الملفات المتأثرة:
  - `lib/core/services/payment_service.dart`
  - `lib/features/booking/presentation/screens/sadad_webview_screen.dart`
  - `lib/features/booking/presentation/screens/payment_method_screen.dart`
- خطوات التنفيذ:
  - استخدام payment/order id الراجع من createSadadPayment في verification.
  - عدم استخدام bookingId كبديل إذا verify يتطلب orderId.
  - مطابقة endpoint مع web backend path.
- الحالات الطرفية:
  - pending.
  - failed.
  - callback متأخر.
- تعريف الإنجاز:
  - Sadad flow يكتمل أو يفشل برسالة واضحة.

### 5.4 إضافة Noqoody / Paymob app-side flow

- الاعتمادات: 5.1.
- الملفات المتأثرة:
  - `lib/core/services/payment_service.dart`
  - `lib/features/booking/presentation/screens/payment_method_screen.dart`
  - webview/deeplink screens جديدة إذا لزم.
- خطوات التنفيذ:
  - إضافة create Paymob intention مثل الويب.
  - إضافة generate Noqoody payment link مثل الويب.
  - فتح payment links داخل webview أو browser flow مناسب.
  - معالجة return/cancel/success.
- الحالات الطرفية:
  - payment provider يرجع link فقط.
  - user abandons payment.
- تعريف الإنجاز:
  - طرق الدفع الأساسية للويب متاحة ومتصلة في Flutter.

## المرحلة 6: الحساب والملف الشخصي والإعدادات

### 6.1 إصلاح logout وسلوك الجلسة

- الاعتمادات: المرحلة 0.
- الملفات المتأثرة:
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/profile/presentation/screens/account_settings_screen.dart`
  - `lib/features/auth/presentation/cubit/auth_cubit.dart`
  - `lib/core/services/user_session.dart`
- خطوات التنفيذ:
  - جعل logout من أي مكان يمسح `UserSession`.
  - تحديث bottom nav/profile prompt بعد logout.
  - عدم الاكتفاء بالانتقال إلى login.
- الحالات الطرفية:
  - فشل Clerk sign out.
  - session corrupted.
- تعريف الإنجاز:
  - بعد logout لا يبقى المستخدم authenticated في أي شاشة.

### 6.2 توسيع Personal Information لمطابقة الويب المهم

- الاعتمادات: 6.1.
- الملفات المتأثرة:
  - `lib/features/profile/presentation/screens/personal_information_screen.dart`
  - `lib/features/profile/presentation/cubit/personal_info_cubit.dart`
  - `lib/core/services/user_service.dart`
  - user/profile models.
- خطوات التنفيذ:
  - تحديث controllers من loaded profile state وليس session القديم فقط.
  - إضافة الحقول المهمة: legal name، DOB، gender، nationality، address، residency country، emergency contact.
  - إضافة رفع صور/ملفات الهوية فقط إذا backend endpoint موجود فعلا.
- الحالات الطرفية:
  - profile ناقص.
  - email/phone read-only.
  - upload fail.
- تعريف الإنجاز:
  - شاشة المعلومات الشخصية تحفظ وتعرض بيانات profile الحقيقية.

### 6.3 تحويل settings غير الفعالة إلى وظائف حقيقية أو إخفائها

- الاعتمادات: 6.1.
- الملفات المتأثرة:
  - `lib/features/profile/presentation/screens/account_settings_screen.dart`
  - `lib/features/profile/presentation/screens/payment_methods_screen.dart`
  - services ذات الصلة.
- خطوات التنفيذ:
  - مراجعة كل زر أو toggle.
  - ربط ما يمكن ربطه بالAPI.
  - إخفاء أو تعطيل مع توضيح واضح لما لا يمكن دعمه الآن.
  - إزالة TODO silent actions.
- الحالات الطرفية:
  - user offline.
  - API لا يدعم feature.
- تعريف الإنجاز:
  - لا يوجد زر ظاهر بلا أثر.

### 6.4 تحسين payment methods/history/payout parity

- الاعتمادات: 5 و6.1.
- الملفات المتأثرة:
  - `lib/features/profile/presentation/screens/payment_methods_screen.dart`
  - `lib/features/profile/presentation/screens/payment_history_screen.dart`
  - `lib/features/profile/presentation/screens/payout_methods_screen.dart`
  - `lib/core/services/user_service.dart`
- خطوات التنفيذ:
  - عرض طرق الدفع والمخرجات بنفس intent الويب.
  - إزالة "قريبا" من الأفعال الأساسية أو تحويلها لحالة disabled واضحة.
  - التأكد من empty/loading/error.
- الحالات الطرفية:
  - لا توجد طرق دفع.
  - API يرجع شكل مختلف.
- تعريف الإنجاز:
  - المستخدم يرى بيانات مالية حقيقية أو empty state واضح.

## المرحلة 7: المضيف ولوحة التحكم وإضافة العقار

### 7.1 إصلاح HostDashboardCubit runtime crash

- الاعتمادات: المرحلة 0.
- الملفات المتأثرة:
  - `lib/features/host/cubit/host_dashboard_cubit.dart`
  - `lib/features/host/cubit/host_dashboard_state.dart`
  - `lib/core/services/host_service.dart`
- خطوات التنفيذ:
  - تغيير state ليقبل `List<PropertyModel>` و`List<BookingModel>` أو تحويل آمن إلى Map.
  - إزالة casts الخاطئة.
  - إضافة tests لنجاح dashboard loading.
- الحالات الطرفية:
  - API يرجع empty.
  - API يرجع wrapper object.
- تعريف الإنجاز:
  - Host dashboard لا ينهار عند تحميل البيانات.

### 7.2 توحيد auth في HostService

- الاعتمادات: 7.1 و6.1.
- الملفات المتأثرة:
  - `lib/core/services/host_service.dart`
  - `lib/core/network/api/dio_consumer.dart`
  - `lib/core/injection/injection_container.dart`
- خطوات التنفيذ:
  - استخدام نفس Dio/API consumer الذي يحقن auth headers.
  - تمرير user/host id كما يتوقع backend.
  - عدم استخدام raw Dio بدون interceptors إلا بسبب موثق.
- الحالات الطرفية:
  - user ليس host.
  - token expired.
- تعريف الإنجاز:
  - host APIs تعمل بنفس session/auth باقي التطبيق.

### 7.3 جعل Add Listing wizard release-grade

- الاعتمادات: 7.2.
- الملفات المتأثرة:
  - `lib/features/host/presentation/screens/list_property_screen.dart`
  - `lib/features/host/presentation/screens/property_wizard_screen.dart`
  - `lib/features/host/presentation/cubit/listing_wizard_cubit.dart`
  - wizard step widgets.
- خطوات التنفيذ:
  - اختيار شاشة wizard واحدة كمسار رسمي.
  - إضافة validation لكل خطوة.
  - إصلاح النصوص العربية المشوهة.
  - حفظ draft/publish بوضوح.
  - تضمين host/user association في payload.
- الحالات الطرفية:
  - صور ناقصة.
  - موقع ناقص.
  - سعر غير صالح.
- تعريف الإنجاز:
  - المضيف يستطيع إنشاء عقار كامل أو حفظ draft بدون crash.

### 7.4 إصلاح رفع الصور والملفات للعقارات

- الاعتمادات: 7.3.
- الملفات المتأثرة:
  - `lib/core/services/host_service.dart`
  - `lib/core/constants/end_points.dart`
  - wizard image steps.
- خطوات التنفيذ:
  - مطابقة endpoint المستخدم في Flutter مع backend/web flow المتاح.
  - دعم progress/error/retry.
  - منع النشر بدون صور إذا المنتج يتطلب ذلك.
- الحالات الطرفية:
  - file too large.
  - network failure.
  - upload succeeds but create listing fails.
- تعريف الإنجاز:
  - صور العقار تظهر في العقار المنشور.

### 7.5 استكمال صفحات Host bookings/earnings/reviews/calendar

- الاعتمادات: 7.1 و7.2.
- الملفات المتأثرة:
  - `lib/features/host/presentation/screens/host_bookings_screen.dart`
  - `lib/features/host/presentation/screens/host_earnings_screen.dart`
  - `lib/features/host/presentation/screens/host_reviews_screen.dart`
  - `lib/features/host/presentation/screens/host_calendar_screen.dart`
  - cubits/services المرتبطة.
- خطوات التنفيذ:
  - ربط كل شاشة بAPI حقيقي أو إخفاؤها من UI حتى تكتمل.
  - إضافة loading/empty/error.
  - إضافة actions الضرورية مثل accept/decline إذا backend يدعمها.
- الحالات الطرفية:
  - مضيف جديد بلا بيانات.
  - API partial failure.
- تعريف الإنجاز:
  - كل عنصر ظاهر في Host dashboard يفتح شاشة مفيدة ومتصلة.

## المرحلة 8: الرسائل والشات

### 8.1 توحيد نظام الرسائل

- الاعتمادات: المرحلة 0 و6.1.
- الملفات المتأثرة:
  - `lib/features/messages/`
  - `lib/features/chat/`
  - `lib/core/services/chat_service.dart`
  - `lib/core/services/socket_service.dart`
- خطوات التنفيذ:
  - اختيار مسار واحد للرسائل في Flutter.
  - مقارنة الويب الذي يستخدم Firestore hooks.
  - إذا Flutter سيستخدم backend/socket، يجب ضمان أنه نفس بيانات المنتج أو bridge backend متاح.
  - إزالة ازدواجية screens/cubits أو جعلها wrappers واضحة.
- الحالات الطرفية:
  - conversation بدون messages.
  - host/guest ids ناقصة.
  - real-time disconnected.
- تعريف الإنجاز:
  - لا توجد مسارات رسائل متنافسة.
  - قائمة المحادثات والمحادثة الفردية تعملان من UI.

### 8.2 إصلاح Contact Host flow

- الاعتمادات: 8.1 و3.3.
- الملفات المتأثرة:
  - `lib/features/messages/presentation/screens/contact_host_screen.dart`
  - `lib/features/property_details/presentation/screens/property_details_screen.dart`
- خطوات التنفيذ:
  - منع فتح contact host بدون propertyId وhostId.
  - إزالة fallback الوهمي للعقار/المضيف.
  - إنشاء conversation ثم الانتقال لها.
- الحالات الطرفية:
  - المستخدم يراسل نفسه.
  - hostId غير موجود.
- تعريف الإنجاز:
  - رسالة المضيف تنشئ conversation حقيقية أو تظهر خطأ واضح.

### 8.3 إضافة حالات real-time واضحة

- الاعتمادات: 8.1.
- الملفات المتأثرة:
  - `lib/features/chat/presentation/screens/chat_conversation_screen.dart`
  - `lib/features/chat/presentation/cubit/chat_cubit.dart`
  - `lib/core/services/socket_service.dart`
- خطوات التنفيذ:
  - عرض connected/disconnected.
  - fallback لإرسال REST إذا socket غير متصل إن كان مدعوما.
  - mark read/unread إذا backend يدعم.
- الحالات الطرفية:
  - reconnection.
  - duplicate messages.
- تعريف الإنجاز:
  - المستخدم يعرف حالة الرسالة ولا تضيع الرسائل بصمت.

## المرحلة 9: الدعم والإشعارات

### 9.1 إصلاح Notifications UX والنصوص

- الاعتمادات: 6.1.
- الملفات المتأثرة:
  - `lib/features/notifications/presentation/screens/notifications_screen.dart`
  - `lib/features/notifications/presentation/cubit/notifications_cubit.dart`
  - `lib/core/services/notification_service.dart`
- خطوات التنفيذ:
  - إصلاح النصوص المشوهة.
  - auth-gate قبل تحميل إشعارات المستخدم.
  - تحسين empty/error states.
  - اختبار mark read/delete.
- الحالات الطرفية:
  - مستخدم غير مسجل.
  - إشعارات كثيرة.
- تعريف الإنجاز:
  - الشاشة مفهومة وجاهزة بصريا ووظيفيا.

### 9.2 مطابقة Support مع قنوات الويب

- الاعتمادات: 6.1.
- الملفات المتأثرة:
  - `lib/features/support/presentation/screens/help_center_screen.dart`
  - `lib/features/support/presentation/screens/contact_support_screen.dart`
  - `lib/features/support/presentation/cubit/support_cubit.dart`
  - `lib/core/services/support_service.dart`
- خطوات التنفيذ:
  - عرض phone/email/WhatsApp/support ticket حسب ما يظهر في الويب.
  - جعل guest user يرى قنوات عامة أو sign-in prompt واضح.
  - إصلاح زر attachment أو إخفاؤه.
- الحالات الطرفية:
  - لا يوجد تطبيق WhatsApp.
  - ticket API failure.
- تعريف الإنجاز:
  - المستخدم يستطيع الوصول للدعم بطريقة واضحة ومفيدة.

## المرحلة 10: Auth والتكاملات الحرجة

### 10.1 مراجعة Clerk integration مقابل الويب

- الاعتمادات: 6.1 والمرحلة 0.
- الملفات المتأثرة:
  - `lib/core/services/clerk_service.dart`
  - `lib/features/auth/presentation/cubit/auth_cubit.dart`
  - `lib/core/services/user_session.dart`
  - `lib/core/network/api/auth_interceptor.dart`
- خطوات التنفيذ:
  - التحقق من أن token المستخدم في Flutter مقبول من backend مثل token الويب.
  - مراجعة refresh/session expiry.
  - توحيد error messages.
  - عدم إضافة app-side config جديدة كبديل عن flow الويب إلا إذا كان ضروريا ومبررا.
- الحالات الطرفية:
  - MFA أو multi-step Clerk.
  - token expired.
  - user exists in Clerk but not backend.
- تعريف الإنجاز:
  - login/signup/session persistence تعمل end-to-end مع backend.

### 10.2 اختبار Google/Apple auth أو إخفاء غير الجاهز

- الاعتمادات: 10.1.
- الملفات المتأثرة:
  - `lib/core/services/google_auth_service.dart`
  - `lib/core/services/apple_auth_service.dart`
  - `lib/features/auth/presentation/screens/login_screen.dart`
  - `lib/features/auth/presentation/screens/sign_up_screen.dart`
- خطوات التنفيذ:
  - التأكد من dart-define/platform config.
  - اختبار Android/iOS.
  - إذا غير جاهز، تعطيل/إخفاء الأزرار من release UI.
- الحالات الطرفية:
  - missing client id.
  - user cancels.
- تعريف الإنجاز:
  - لا يظهر خيار social auth غير صالح للنشر.

## المرحلة 11: التلميع البصري وتجربة المنتج

### 11.1 توحيد اللغة والنصوص

- الاعتمادات: المراحل الوظيفية الأساسية.
- الملفات المتأثرة:
  - كل screens التي تعرض Arabic/English mixed text.
- خطوات التنفيذ:
  - إصلاح mojibake.
  - توحيد المصطلحات.
  - إزالة النصوص المؤقتة و"قريبا" من flows أساسية.
- الحالات الطرفية:
  - اتجاه RTL/LTR.
  - أرقام وأسعار.
- تعريف الإنجاز:
  - لا توجد نصوص مشوهة في أي شاشة release.

### 11.2 تحسين loading/empty/error states

- الاعتمادات: المراحل 2 إلى 9.
- الملفات المتأثرة:
  - shared widgets.
  - feature screens.
- خطوات التنفيذ:
  - استخدام skeletons وempty states الموجودة.
  - توحيد retry actions.
  - منع blank screens.
- الحالات الطرفية:
  - API timeout.
  - unauthorized.
  - no data.
- تعريف الإنجاز:
  - كل شاشة رئيسية لها loading/empty/error/success واضح.

### 11.3 مراجعة action hierarchy

- الاعتمادات: المراحل 2 إلى 9.
- الملفات المتأثرة:
  - Home/Search/Details/Booking/Profile/Host screens.
- خطوات التنفيذ:
  - جعل CTA الأساسي واضحا في كل شاشة.
  - إزالة buttons غير فعالة.
  - auth-gate للأفعال المحمية.
- الحالات الطرفية:
  - guest user.
  - host user.
  - normal user.
- تعريف الإنجاز:
  - المستخدم يعرف الخطوة التالية ولا يضغط على أزرار ميتة.

## المرحلة 12: الاختبار النهائي وجاهزية النشر

### 12.1 تشغيل static analysis والاختبارات

- الاعتمادات: كل المراحل السابقة.
- الملفات المتأثرة: لا يوجد تعديل مباشر.
- خطوات التنفيذ:
  - `flutter analyze`.
  - `flutter test`.
  - معالجة كل error وكل warning مهم.
- الحالات الطرفية:
  - tests flaky بسبب network.
- تعريف الإنجاز:
  - analysis clean أو warnings موثقة وغير حارقة.

### 12.2 QA runtime على Android emulator

- الاعتمادات: 12.1.
- الملفات المتأثرة: لا يوجد تعديل مباشر إلا إذا ظهرت bugs.
- خطوات التنفيذ:
  - تشغيل التطبيق على emulator.
  - اختبار guest browsing.
  - اختبار login.
  - اختبار search/filter.
  - اختبار details.
  - اختبار booking.
  - اختبار payment sandbox.
  - اختبار profile/settings.
  - اختبار host flow.
  - اختبار chat/support/notifications.
- الحالات الطرفية:
  - backend staging غير متاح.
  - payment sandbox credentials ناقصة.
- تعريف الإنجاز:
  - كل flow حرج موثق بنتيجة pass/fail.

### 12.3 QA runtime على iOS

- الاعتمادات: 12.1.
- الملفات المتأثرة:
  - `ios/` إذا ظهرت مشاكل platform config.
- خطوات التنفيذ:
  - تشغيل على simulator/device.
  - اختبار auth/social auth/deeplinks/payment webviews.
  - اختبار permissions.
- الحالات الطرفية:
  - Apple auth config.
  - deep link return.
- تعريف الإنجاز:
  - iOS لا يملك blockers مختلفة عن Android.

### 12.4 بناء release artifacts

- الاعتمادات: 12.2 و12.3.
- الملفات المتأثرة:
  - build configs فقط إذا ظهر فشل.
- خطوات التنفيذ:
  - `flutter build apk --release`.
  - `flutter build appbundle --release` إن كان مطلوبا للمتجر.
  - `flutter build ios --release`.
  - تمرير dart-defines الصحيحة.
- الحالات الطرفية:
  - missing signing config.
  - missing API keys.
- تعريف الإنجاز:
  - artifacts تبنى بنجاح وجاهزة للنشر الداخلي.

### 12.5 Release readiness sign-off

- الاعتمادات: 12.4.
- الملفات المتأثرة:
  - `docs/usability_and_release_readiness_audit.md`
  - هذا الملف.
  - ملف release notes إن وجد.
- خطوات التنفيذ:
  - إعادة تدقيق الأقسام نفسها في التقرير الأصلي.
  - تحديث status لكل section إلى Ready أو Mostly Ready.
  - توثيق أي known limitations غير حارقة.
- الحالات الطرفية:
  - أي flow payment/booking/auth لم ينجح لا يسمح بالنشر.
- تعريف الإنجاز:
  - التطبيق قابل للتصفح والحجز والدفع وإدارة الحساب والمضيف والرسائل بدون blockers.

## ترتيب التنفيذ المقترح

1. المرحلة 0: البناء والcompile blockers.
2. المرحلة 1: الملاحة وroute arguments.
3. المرحلة 2 و3: البحث وتفاصيل العقار.
4. المرحلة 4 و5: الحجز والدفع.
5. المرحلة 6: الحساب والجلسة.
6. المرحلة 7: المضيف.
7. المرحلة 8: الرسائل.
8. المرحلة 9: الدعم والإشعارات.
9. المرحلة 10: auth/social integrations.
10. المرحلة 11: التلميع البصري.
11. المرحلة 12: QA والنشر.

## معايير عدم السماح بالنشر

- أي compile error.
- أي route ظاهر للمستخدم يفتح شاشة فارغة أو route غير مسجل.
- أي payment method ظاهر ولا يعمل end-to-end.
- تفاصيل العقار لا تفتح من كل بطاقات العقارات.
- إنشاء الحجز لا يتحقق من التوفر والسعر من backend.
- تسجيل الدخول أو logout غير موثوق.
- لوحة المضيف تنهار أو تظهر بيانات وهمية كأنها حقيقية.
- الرسائل لا تفتح أو لا ترسل.
- وجود نصوص مشوهة في شاشات رئيسية.
- عدم وجود runtime QA فعلي على الأقل Android قبل النشر.
