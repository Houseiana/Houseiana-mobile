# قائمة مهام إصلاح جاهزية النشر

> آخر تحديث: 2026-04-24  
> القاعدة الثابتة: لا تعديل على مشروع الويب نهائيًا. كل التنفيذ داخل Flutter فقط.

## تم في الجولة الأخيرة

| الكود | المهمة | الملفات | الحالة |
|---|---|---|---|
| UX-1 | ربط شاشة `Personal Information` ببيانات المستخدم الفعلية من الـ API بدل الاكتفاء ببيانات الجلسة المحلية، مع حالات تسجيل دخول/تحميل/خطأ أوضح | `personal_information_screen.dart`, `personal_info_cubit.dart`, `personal_info_state.dart` | تم |
| UX-2 | تحسين شاشة `Host Earnings` لتصبح صالحة للمستخدم الفعلي: حالة عدم تسجيل الدخول، إعادة المحاولة، حالة فارغة مفهومة، وتحديث بالسحب | `host_earnings_screen.dart`, `app_colors.dart` | تم |
| UX-3 | تحسين شاشة `Host Payout Methods` وإزالة الـ UX الخام: نموذج إضافة بنك حقيقي مع validation، حالة تسجيل دخول، حالة خطأ/فارغة، ورسائل نجاح/فشل أوضح | `host_payout_screen.dart`, `app_colors.dart` | تم |
| HOST-3 | تحويل خطوة صور العقار من زر وهمي "coming soon" إلى رفع صور فعلي عبر `image_picker` وربطها بـ `HostService.uploadPhoto` مع إمكانية الحذف | `step_06_photos_screen.dart`, `listing_wizard_cubit.dart` | تم |
| HOST-4 | منع الانتقال أو النشر قبل استيفاء الحد الأدنى للصور في الـ wizard | `listing_wizard_cubit.dart`, `property_wizard_screen.dart`, `list_property_screen.dart` | تم |
| BUILD-1 | إضافة ألوان `neutral50` و `neutral500` و `neutral700` داخل `AppColors` لسد references مكسورة كانت قد تمنع البناء | `app_colors.dart` | تم |
| BUILD-2 | إصلاح import ناقص في شاشة `Review & Publish` | `step_13_review_publish_screen.dart` | تم |

## تم في الجولة الحالية

| الكود | المهمة | الملفات | الحالة |
|---|---|---|---|
| PAY-1 | إزالة شاشة الدفع القديمة المعتمدة على Stripe من المسار الفعلي | `lib/features/booking/presentation/screens/payment_screen.dart`, `lib/core/injection/booking_injection.dart` | تم |
| PAY-2 | تحويل طرق الدفع في الملف الشخصي من PayPal "قريبًا" إلى تدفق فعلي بإضافة البريد | `payment_methods_screen.dart`, `payment_methods_cubit.dart`, `user_service.dart`, `user_model.dart` | تم |
| ACC-1 | إصلاح أفعال Account Settings الصامتة | `account_settings_screen.dart` | تم |
| ADDR-1 | إصلاح `SavedAddressesCubit` من `_userSession.id` إلى `userId` | `saved_addresses_cubit.dart` | تم |
| ADDR-2 | تحويل تعديل العنوان وتعيينه كافتراضي من أفعال وهمية إلى API | `saved_addresses_screen.dart`, `saved_addresses_cubit.dart`, `saved_addresses_state.dart`, `user_service.dart` | تم |
| HOST-1 | إزالة tap فارغ من كارت Properties في Host Dashboard | `host_dashboard_screen.dart` | تم |
| HOST-2 | استبدال شاشة Host Reviews الفارغة بشاشة بيانات فعلية من عقارات المضيف | `host_reviews_screen.dart` | تم |
| AUTH-1 | إخفاء Apple Sign-In لأنه Stub غير جاهز وترك Google فقط ظاهرًا | `login_screen.dart`, `sign_up_screen.dart`, `apple_auth_service.dart` | تم |
| CHAT-1 | إصلاح compile blocker في المحادثات بسبب `_session.token` غير الموجود | `chat_conversation_screen.dart` | تم |
| CHAT-2 | إصلاح تحميل رسائل المحادثة من `response.data` وربط `ChatCubit` بخدمات DI | `chat_service.dart`, `chat_cubit.dart` | تم |
| CHAT-3 | إزالة بيانات Contact Host الوهمية وإضافة تحقق من تسجيل الدخول وبيانات العقار/المضيف | `contact_host_screen.dart` | تم |

## تم سابقًا

| المجال | ملخص |
|---|---|
| Routing | تسجيل routes أساسية مثل Home وProperties وProfile وPayment وProperty details sub-screens |
| Booking/Payment | تحويل الدفع الظاهر إلى Noqoody وPaymob وPayPal وSADAD بدل شاشة Stripe القديمة |
| Search | ربط الفلاتر المتقدمة بنتائج البحث بدل تجاهلها |
| Host | إصلاح Dashboard وEarnings وBookings typed loading |
| Support | إزالة attachment الوهمي وإتاحة الاتصال والبريد وWhatsApp |
| Notifications | تنظيف النصوص والحالات المرئية |

## المتبقي قبل اعتبار التطبيق جاهزًا 100%

| الأولوية | المهمة | السبب | النوع |
|---|---|---|---|
| حرجة | تشغيل `flutter analyze` بنجاح | الأداة علّقت في البيئة الحالية ولا يوجد تأكيد نهائي للتجميع | تحقق |
| حرجة | تشغيل التطبيق على محاكي/جهاز واختبار المسارات | لم يتم التحقق البصري/الفعلي بعد | Runtime |
| حرجة | اختبار Paymob/Noqoody/SADAD/PayPal مع backend فعلي | الكود مربوط لكن نجاح الدفع يحتاج sandbox/backend فعلي | Integration |
| حرجة | تأكيد backend production/staging الموحد مع الويب | لا يمكن حسمه من Flutter فقط | API |
| حرجة | تأمين مسار Clerk بالكامل عبر backend مناسب | Flutter ما زال يعتمد على تكامل Clerk مباشر في أجزاء من المصادقة | Auth |
| عالية | اختبار Host listing wizard مع رفع صور حقيقي ونشر عقار فعلي | الكود ظاهر لكن يحتاج تحقق end-to-end | Flow |
| عالية | اختبار Chat end-to-end بين ضيف ومضيف | تم إصلاح wiring واضح لكن يحتاج تشغيل backend/socket | Messaging |
| عالية | مراجعة كل النصوص القديمة تالفة الترميز في الشاشات غير المعدلة | بعض الملفات القديمة قد تظهر mojibake على UI | UI polish |
| متوسطة | إزالة/تعطيل خدمات غير ظاهرة مثل Stripe إن تقرر عدم استخدامها نهائيًا | تنظيف release surface | Cleanup |

## نتيجة الحالة الحالية

التطبيق تحسن بوضوح في الدفع، الحساب، العناوين، مراجعات المضيف، المصادقة الاجتماعية، والرسائل. لكنه لا يزال غير مؤكد الجاهزية بنسبة 100% لأن التحليل والتشغيل الفعلي لم ينجحا في هذه البيئة، ولأن الدفع والمحادثات والاستضافة تحتاج اختبار backend حقيقي قبل النشر.

## Update 2026-04-25

| Code | Task | Files | Status |
|---|---|---|---|
| SEARCH-2 | Confirmed that `LocationSearchScreen` no longer uses fake popular/recent destinations and now reads live locations from property data | `location_search_screen.dart` | Done |
| BOOK-3 | Removed misleading receipt/download behavior from booking confirmation and replaced it with a real receipt summary + copy action | `booking_confirmation_screen.dart` | Done |
| BOOK-4 | Fixed Contact Host from booking confirmation to use real `hostId` from booking property summary and block navigation when host data is unavailable | `booking_confirmation_screen.dart`, `booking_model.dart` | Done |
| HOST-5 | Rebuilt `HostBookingsScreen` to use real `BookingModel` objects instead of map-based fake typing in the UI | `host_bookings_screen.dart` | Done |
| HOST-6 | Added clear login-required and retry/error states to `HostBookingsScreen` so the feature is reachable and understandable for real users | `host_bookings_screen.dart` | Done |
| HOST-7 | Added login-required and retry/error states to `HostDashboardScreen` instead of silently rendering empty stats on auth/API failure | `host_dashboard_screen.dart` | Done |
| KYC-1 | Added login gate to KYC verification so the screen no longer falls through to raw `Not logged in` submission errors | `kyc_verification_screen.dart` | Done |
| KYC-2 | Cleaned broken navigation labels/tips text in KYC and kept the flow usable with clearer step actions | `kyc_verification_screen.dart` | Done |

### Remaining high-priority verification

- `dart analyze` / `flutter analyze` still times out in this environment, so compile-clean status is not fully confirmed.
- Runtime verification on emulator/device is still required for:
  - host dashboard
  - host bookings
  - booking confirmation -> contact host
  - KYC document flow
- End-to-end backend validation is still required for payments, chat, host listing publish, and booking completion.

## Update 2026-04-25 - Second parity cleanup batch

| Code | Task | Files | Status |
|---|---|---|---|
| SEARCH-3 | Removed static popular destinations from the search modal and generated destination suggestions from live property data | `search_modal_screen.dart` | Done |
| COUNTRY-1 | Replaced hardcoded countries, cities, images, flags, and property counts with live country/city groups built from current property listings | `country_screen.dart`, `city_list_screen.dart` | Done |
| WISH-1 | Removed fake wishlist cards and local create/delete wishlist behavior; screen now shows real saved homes from favorites API | `wishlists_screen.dart` | Done |
| PRIV-1 | Rebuilt privacy settings to load/save the same `privacySettings` metadata shape used by the web product in Clerk public metadata | `privacy_settings_screen.dart`, `clerk_service.dart` | Done |
| PRIV-2 | Replaced fake privacy SnackBar actions with real data-request metadata flow and support handoff for account deletion safety | `privacy_settings_screen.dart`, `clerk_service.dart` | Done |
| LANG-1 | Removed unsupported/broken language list and wired language selection to real `LocaleCubit` persistence | `language_settings_screen.dart`, `app.dart`, `app_localizations.dart` | Done |
| CUR-1 | Cleaned broken currency symbols and persisted selected currency locally instead of losing state after leaving the screen | `currency_settings_screen.dart` | Done |

### Verification after second batch

- Text sweep no longer finds: `coming soon`, `_popularDestinations`, `Dream Vacation`, `Summer Vacation`, `Data download requested`, `Search history cleared`, `Browsing data cleared`, or `Navigate to wishlist detail` in Flutter feature code.
- `git diff --check` passes for the touched files with only CRLF warnings.
- `dart analyze` still times out in this environment even for targeted file sets; runtime/emulator verification is still required before any 100% release claim.

## Update 2026-04-25 - Auth parity + Home screen parity + Stub removal batch

| Code | Task | Files | Status |
|---|---|---|---|
| AUTH-2 | Fixed OTP resend navigating home immediately — introduced `AuthCodeResent` state so resend shows a SnackBar without triggering navigation | `auth_cubit.dart`, `auth_state.dart`, `otp_verification_screen.dart` | Done |
| AUTH-3 | Added Terms & Privacy checkbox to sign-up screen with routes to legal screens and validation before submit | `sign_up_screen.dart`, `app_strings.dart` | Done |
| AUTH-4 | Added clipboard paste shortcut on OTP screen — fills all 6 boxes and auto-submits when 6 digits detected | `otp_verification_screen.dart`, `app_strings.dart` | Done |
| HOME-1 | Added city-grouped property sections to home screen matching web's PropertyGrid layout (rotating headings, See All links) | `home_screen.dart` | Done |
| HOME-2 | Fixed property card: Guest Favorite badge color (#FCC519), discount badge bottom-left, amenity row (beds/baths/rooms) | `home_screen.dart` | Done |
| HOME-3 | Passed missing PropertyModel fields (currency, priceWithoutDiscount, weeklyDiscount, smallBookingDiscount, beds) through card builder | `property_model.dart`, `home_screen.dart` | Done |
| PASS-1 | Wired Change Password screen from fake AlertDialog to real `ClerkService.changeUserPassword()` with loading state and error/success SnackBar | `change_password_screen.dart`, `clerk_service.dart` | Done |
| REV-1 | Rebuilt Review Property screen from bare stub to full star rating + comment form using `ReviewSubmissionCubit` and `RatingsService` | `review_property_screen.dart` | Done |
| FAV-1 | Fixed property details favorite toggle to call `UserService.toggleFavorite()` with optimistic update + API rollback; initialized from `isFavourited` field in loaded state | `property_details_screen.dart` | Done |

### Remaining for 100% production readiness

- `dart analyze` / `flutter analyze` still times out — compile-clean status unconfirmed in this environment.
- Runtime device/emulator verification still required for all changed screens.
- Payments (Paymob/Noqoody/SADAD/PayPal), Chat end-to-end, and Host listing publish need real backend/sandbox testing.
