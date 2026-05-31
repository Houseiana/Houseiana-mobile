# 1) Executive Readiness Summary

- الحقيقة العامة: تطبيق Flutter ليس جاهزا للنشر حاليا. توجد أجزاء مرئية وقابلة للتصفح جزئيا مثل الصفحة الرئيسية، البحث، بعض تفاصيل العقار، الملف الشخصي، المفضلة، والرحلات، لكن التجربة ليست متصلة end-to-end بنفس قوة منتج الويب.
- التطبيق لا يشعر بالكامل مثل منتج الويب. الويب هو مصدر الحقيقة وفيه تدفقات أوضح وأكثر اكتمالا للبحث، الحجز، الدفع، الحساب، لوحة المضيف، والرسائل. في Flutter توجد شاشات كثيرة، لكن عددا كبيرا منها إما غير ظاهر من الملاحة الأساسية، أو ظاهر لكن غير موصل فعليا، أو يستخدم مسار تكامل مختلف عن الويب.
- التطبيق غير publish-ready. توجد بلوكرز حرجة: رسائل قد لا تبني أصلا بسبب استدعاء `UserService.getConversations` غير الموجود، دفع غير مطابق لمسار الويب، تفاصيل العقار تنكسر من تبويب البحث، لوحة المضيف فيها cast خاطئ يسبب runtime failure، وتدفق الحجز لا يستخدم نفس تحقق التوفر والسعر الموجود في الويب.
- سبب الإحساس بعدم الاكتمال: كثير من العمل بنيوي فقط. توجد routes وscreens وservices، لكن الظهور الفعلي للمستخدم ضعيف في عدة مناطق، وبعض الأزرار لا تحفظ أو لا تنفذ، وبعض الشاشات تستخدم بيانات محلية أو fallback أو TODO، وبعض التكاملات تستخدم endpoints أو services مختلفة عن الويب.
- نتيجة الجاهزية: كمنتج قابل للاستخدام الفعلي، التطبيق أقرب إلى Partial / Not Release-Ready. يمكن لمستخدم مجهول أن يتصفح جزءا من العقارات من مسارات معينة، لكن مستخدم حقيقي سيتعطل عند تفاصيل عقار من تبويب البحث، الحجز/الدفع، الرسائل، المضيف، وبعض إعدادات الحساب.

# 2) Section-by-Section Visibility and Usability Audit

## Home

- هدف القسم في الويب: الصفحة الرئيسية في `Houseiana-Holidays-Homes-main_web/src/app/page.tsx` تعرض `HomeClient` من `features/home/components/HomeClient.tsx`. الويب يعرض header، hero/search، `PropertyGrid`، `PropertyFilter`، وتجميع العقارات حسب البلد مع تحميل تدريجي.
- المحتوى المتوقع في الويب: بحث، فلاتر propertyType والسعر والغرف والحمامات والتقييم والمرافق والضيوف، بطاقات عقارات، مفضلة، country grouping، وتجربة discovery مستمرة.
- Flutter equivalent: `lib/features/home/presentation/screens/home_screen.dart`.
- Reachable in UI: نعم، لأن `lib/app.dart` يبدأ مباشرة من `Routes.bottomNav` و`BottomNavScreen` يجعل Home أول تبويب.
- Visible to users: نعم.
- Actually usable: جزئيا. يعرض عقارات من `PropertyService.getProperties`، وفيه search entry وcategory chips وtrending destinations وproperty cards.
- Matches web intent: جزئي. الصفحة تحاول إعطاء إحساس discovery، لكنها لا تطابق قوة web filtering. category chips تغير `_selectedCategory` فقط ولا تظهر دليلا كافيا أنها تعيد طلب API بنفس فلاتر الويب. الويب يستخدم `BackendAPI.Property.publicSearchFilter` بفلترة واسعة، بينما Flutter Home يستخدم list أبسط.
- Status: Partial.
- Main gaps: الفلاتر الأساسية ليست بنفس تكامل الويب، زر `List Your Home` يذهب إلى listing بدون بوابة auth واضحة، الصفحة لا تثبت نفس رحلة `PropertyFilter` وcountry grouping الموجودة في الويب.

## Discover / Explore

- هدف القسم في الويب: `/discover` في `app/discover/DiscoverClient.tsx` يعرض Discover Header، filters، listings، map/list view، pagination، bounds، وfavorites. الويب يستخدم hook `use-discover.ts` الذي يستدعي `BackendAPI.Property.publicSearchFilter`.
- المحتوى المتوقع: بحث وجهة، فلاتر متقدمة، view mode map/list، نتائج قابلة للفرز والتصفح، بطاقات عقار، مفضلة، وتحديث النتائج حسب bounds والفلاتر.
- Flutter equivalent: `lib/features/discover/presentation/screens/discover_screen.dart` و`lib/features/properties/presentation/screens/properties_screen.dart`.
- Reachable in UI: تبويب Search يعرض `PropertiesScreen`، لكن `DiscoverScreen` نفسها ليست جزءا واضحا من bottom navigation.
- Visible to users: Search visible، Discover الكاملة hidden/weakly surfaced.
- Actually usable: جزئيا. `PropertiesScreen` تحمل العقارات وتعرضها، لكن الفلاتر المتقدمة ترجع نتائج إلى الشاشة ثم يتم تجاهلها عمليا، لأن الشاشة تنفذ `_loadData()` بدون استخدام القيم المرتجعة.
- Matches web intent: ضعيف. الويب يملك discover experience حقيقية، بينما Flutter Search tab أقرب إلى list بسيطة مع خريطة شكلية/gradient markers وليست map parity.
- Status: Partial / Not Release-Ready.
- Main gaps: `DiscoverScreen` غير مسطح كمركز discovery أساسي، الفلاتر لا تؤثر من `PropertiesScreen`، الخريطة ليست map فعلية، وتمرير العقار إلى التفاصيل من هذه الشاشة مكسور.

## Search / Filter / Discovery

- هدف القسم في الويب: البحث والفلاتر في home/discover تستخدم نفس API الغني `publicSearchFilter` وتدعم location، price، bedrooms، beds، bathrooms، amenities، rating، guests، pagination.
- Flutter equivalent: `SearchModalScreen`, `AdvancedFiltersScreen`, `SearchPropertiesScreen`, `PropertiesScreen`.
- Reachable in UI: نعم من Home وSearch tab، لكن بجودة مختلفة.
- Visible to users: نعم.
- Actually usable: جزئيا. `SearchModalScreen` يرسل إلى `Routes.searchProperties` و`SearchPropertiesScreen` يستخدم `SearchCubit.searchProperties` ويطبق بعض الفلاتر. لكن `PropertiesScreen` التي هي تبويب أساسي تتجاهل نتائج الفلتر.
- Matches web intent: جزئي فقط. المسار الأفضل موجود لكنه ليس المسار الوحيد ولا الأكثر ثباتا. المسار الرئيسي في bottom tab لا يطبق الفلاتر مثل الويب.
- Status: Partial.
- Main gaps: ازدواجية بين `PropertiesScreen` و`SearchPropertiesScreen`، فلاتر لا تعمل في الشاشة الرئيسية للبحث، map parity ضعيفة، وعدم توحيد API search behavior مثل web.

## Property Details

- هدف القسم في الويب: `/property/[id]` يعرض تفاصيل العقار مع صور، وصف، مرافق، قواعد، تقييمات، خريطة، وbooking card sticky. `features/property/components/booking-card.tsx` يتحقق من server time، blocked/booked dates، minimum nights، guests، availability/pricing API، وprice breakdown.
- Flutter equivalent: `lib/features/property_details/presentation/screens/property_details_screen.dart` مع `PropertyDetailsCubit`.
- Reachable in UI: نعم من بعض المسارات، لكن ليس بشكل آمن من كل المسارات.
- Visible to users: جزئيا.
- Actually usable: غير موثوق. `PropertiesScreen` يفتح التفاصيل بـ `arguments: p`، بينما route في `AppRoutes` يتوقع `args['propertyId']` أو `args['property']`. النتيجة أن `propertyIdToLoad` قد يصبح فارغا وتبقى الشاشة في `PropertyDetailsInitial` مع `SizedBox.shrink()`.
- Matches web intent: جزئي. يوجد layout تفصيلي، لكن booking card والتوفر والتقييمات لا يطابقان الويب. في `_init()` يتم استدعاء `loadRatings` و`loadAvailability` مباشرة بعد `getPropertyDetails` بدون انتظار اكتمال حالة `PropertyDetailsLoaded`، بينما cubit يرجع مبكرا إذا لم تكن الحالة loaded، وهذا يجعل rating/availability غالبا لا تحمل عند البداية.
- Status: Broken من Search tab، Partial من Home/SearchProperties.
- Main gaps: تمرير arguments مكسور من شاشة رئيسية، availability/ratings loading غير مضمون، booking UX أقل من الويب، عدم وجود server-time/min-nights/blocked-date continuity مثل web.

## Booking

- هدف القسم في الويب: `/booking/confirm` يستخدم `BookingConfirmContent.tsx` و`use-booking-confirm.ts`. الويب يأخذ propertyId/checkIn/checkOut/guests من query، يجلب property + availability/pricing، يتحقق من التواريخ، يعرض guest details، payment method، وprice breakdown قبل إنشاء/دفع الحجز.
- Flutter equivalent: `BookingRequestScreen`, `BookingCubit`, `UserService.createBooking`, وبعض شاشات الدفع.
- Reachable in UI: نعم من `PropertyDetailsScreen` عبر زر الحجز إذا المستخدم مسجل.
- Visible to users: نعم جزئيا.
- Actually usable: جزئيا إلى ضعيف. الشاشة تجمع check-in/check-out/guests وتبني سعر محلي من بيانات العقار، ثم تنشئ booking. لا يظهر أنها تستخدم نفس availability/pricing validation الموجود في الويب.
- Matches web intent: ضعيف. الويب يجعل الحجز قائما على تحقق availability/pricing من backend، بينما Flutter يعتمد أكثر على حساب محلي وbody مختلف.
- Status: Partial / Not Release-Ready.
- Main gaps: عدم مطابقة flow الويب، مخاطر DTO mismatch في `UserService.createBooking`، عدم وضوح guest details، ضعف حالات تعارض التواريخ والسعر النهائي.

## Payment

- هدف القسم في الويب: الدفع في `use-booking-confirm.ts` يدعم credit card عبر Paymob intention، PayPal، Sadad عبر `/api/sadadpayment/initiate`، وNoqoody عبر `generateNoqoodyPaymentLink`. default في الويب `noqoody`.
- Flutter equivalent: `PaymentMethodScreen`, `PaymentService`, `StripePaymentService`, `PayPalPaymentService`, `PaypalWebViewScreen`, `SadadWebViewScreen`.
- Reachable in UI: نعم بعد إنشاء booking.
- Visible to users: نعم.
- Actually usable: غالبا لا. Flutter يعرض Stripe/PayPal/Sadad، بينما الويب يستخدم Paymob/Noqoody/Sadad/PayPal. `PaypalWebViewScreen` يلتقط PayPal باستخدام `userId: ''`، و`SadadWebViewScreen` ينادي `verifySadadPayment(widget.bookingId)` رغم أن verify يتوقع orderId. Sadad endpoint في Flutter مختلف عن الويب.
- Matches web intent: لا. هذا اختلاف تكامل جوهري وليس مجرد UI.
- Status: Broken / Not Release-Ready.
- Main gaps: Stripe بدلا من Paymob credit card، عدم وجود Noqoody كمسار ويب رئيسي، PayPal capture ناقص userId، Sadad verification يستخدم bookingId بدلا من orderId، endpoints غير مطابقة للويب.

## Account / Profile / Settings

- هدف القسم في الويب: `/account/*` و`/client-dashboard?tab=account` يقدمون ملف شخصي غني، personal info، payments، payout، identity/contact/profile management. `personal-info` في الويب يدعم country/city lookups، gender، photo upload، legal name، DOB، nationality، email/phone، address، residency، passport، national ID، emergency contact.
- Flutter equivalent: `ProfileScreen`, `PersonalInformationScreen`, `AccountSettingsScreen`, `PaymentMethodsScreen`, `PaymentHistoryScreen`, `SavedAddressesScreen`, `PayoutMethodsScreen`.
- Reachable in UI: نعم للملف الشخصي من bottom tab بعد تسجيل الدخول.
- Visible to users: نعم.
- Actually usable: جزئيا. القائمة ظاهرة وبعض الشاشات موجودة. لكن بعض الإعدادات محلية فقط، حذف الحساب TODO، 2FA/phone/email actions غير فعالة، وpersonal info أقل بكثير من الويب.
- Matches web intent: جزئي ضعيف. Flutter يغطي الشكل العام للحساب، لكنه لا يغطي عمق identity/profile/payment management الموجود في الويب.
- Status: Partial.
- Main gaps: حقول هوية ناقصة، رفع ملفات ناقص، إعدادات غير محفوظة، logout في `ProfileScreen` ينتقل فقط إلى login ولا يثبت مسح الجلسة مثل `AccountSettingsScreen`.

## Host Dashboard

- هدف القسم في الويب: `features/dashboard/components/host-dashboard-content.tsx` يعرض host stats، add property، calendar/messages، properties table، bookings، statuses/actions، ويرتبط بصفحات host dashboard الكثيرة.
- Flutter equivalent: `HostDashboardScreen`, `HostDashboardCubit`, `HostService`, `HostBookingsScreen`, `HostListingsScreen`, `HostEarningsScreen`, `HostReviewsScreen`, `PropertyWizardScreen`, `ListPropertyScreen`.
- Reachable in UI: نعم من Profile، وأحيانا من host tab إذا `session.isHost`.
- Visible to users: جزئيا.
- Actually usable: لا بشكل موثوق. `HostDashboardCubit.loadDashboard` يستخدم `Future.wait` ثم يعمل cast لـ `results[0]` و`results[1]` إلى `List<Map<String,dynamic>>`، بينما `HostService.getHostListings` يرجع `List<PropertyModel>` و`getHostBookings` يرجع `List<BookingModel>`. هذا runtime crash محتمل.
- Matches web intent: ضعيف. حتى لو ظهرت، تدفق المضيف ليس بنفس اكتمال status/actions/listings/bookings/revenue في الويب.
- Status: Broken / Not Release-Ready.
- Main gaps: crash محتمل، `HostService` يستخدم Dio خام بدون auth interceptor واضح، `ListPropertyScreen` فيه نصوص mojibake، validation ضعيف، والwizard الأقوى ليس هو المسار الظاهر دائما.

## Host Listings / Wizard

- هدف القسم في الويب: إضافة وإدارة عقار مع خطوات منظمة ورفع صور وحالة مراجعة ونشر.
- Flutter equivalent: `ListPropertyScreen`, `PropertyWizardScreen`, `ListingWizardCubit`.
- Reachable in UI: نعم من Home/Profile/Host Dashboard عبر `Routes.listProperty`; `Routes.propertyWizard` موجود لكن أقل ظهورا.
- Visible to users: نعم جزئيا.
- Actually usable: ضعيف. `ListPropertyScreen` ينتقل بالخطوات بدون validation كاف، ويحتوي نصوص عربية مشوهة. `WizardData.toApiMap()` لا يظهر أنه يرسل hostId/userId، وupload endpoint قد لا يطابق backend/web flow.
- Matches web intent: جزئي ضعيف.
- Status: Partial / Not Release-Ready.
- Main gaps: validation، auth/host association، upload، status lifecycle، ووضوح النصوص.

## Host Bookings / Reviews / Earnings

- هدف القسم في الويب: صفحات المضيف تعرض حجوزات، تقويم، أرباح، إحصاءات، رسائل، مراجعات، وتحليلات.
- Flutter equivalent: `HostBookingsScreen`, `HostCalendarScreen`, `HostEarningsScreen`, `HostReviewsScreen`, `HostInsightsScreen`, `HostMessagesScreen`.
- Reachable in UI: بعض الشاشات من dashboard/routes، لكن ليس كلها واضحة من رحلة المستخدم.
- Visible to users: جزئيا.
- Actually usable: جزئي إلى ضعيف. بعض الخدمات موجودة، لكن host dashboard الأساسي نفسه معرض للكسر، فيضعف الوصول للكل.
- Matches web intent: ضعيف.
- Status: Partial / Broken depending route.
- Main gaps: عدم ثبات dashboard، اختلاف auth، نقص actions، وبيانات/حالات غير مثبتة runtime.

## Support / Help

- هدف القسم في الويب: `/support`, `/help-center`, `/contact-support` تعرض direct support channels مثل phone/email/WhatsApp ومحتوى مساعدة.
- Flutter equivalent: `HelpCenterScreen`, `ContactSupportScreen`, `SupportCubit`, `SupportService`.
- Reachable in UI: نعم من Profile وبعض routes.
- Visible to users: نعم.
- Actually usable: جزئيا. `ContactSupportScreen` يرسل ticket عبر `/api/support` لكنه يتطلب login من `UserSession`; attachment button فارغ؛ ولا تظهر نفس قنوات الاتصال المباشرة بوضوح مثل الويب.
- Matches web intent: جزئي.
- Status: Partial.
- Main gaps: no direct WhatsApp/email/phone parity، attachment fake، handling للضيف ضعيف، و`SupportService` يستخدم Dio خام بدون auth واضح.

## Notifications

- هدف القسم في الويب: إشعارات مرتبطة بحساب المستخدم والنشاط.
- Flutter equivalent: `NotificationsScreen`, `NotificationsCubit`, `NotificationService`.
- Reachable in UI: نعم من Home/Profile/Host dashboard.
- Visible to users: نعم.
- Actually usable: جزئيا. لو المستخدم غير مسجل، الخدمة ترجع "User not found" بدلا من تجربة sign-in واضحة. الشاشة تحتوي نصوص عربية مشوهة mojibake.
- Matches web intent: جزئي.
- Status: Partial / Not Release-Ready for polish.
- Main gaps: auth gating، mojibake، empty/error UX.

## Chat / Messages

- هدف القسم في الويب: `/messages` وclient dashboard chat يستخدمان Firestore hooks مثل `useFirebaseChat` و`useFirebaseConversations` مع real-time messages/unread.
- Flutter equivalent: `ConversationsScreen`, `ChatConversationScreen`, `ContactHostScreen`, `ChatCubit`, `ChatService`, `SocketService`.
- Reachable in UI: نعم عبر profile/messages/contact host، لكن قابلية البناء/التشغيل مشكوك فيها.
- Visible to users: جزئيا.
- Actually usable: Broken. `ConversationsScreen` يستدعي `_userService.getConversations(_session.userId!)`، لكن `UserService` لا يحتوي `getConversations`; الموجود في `ChatService`. هذا compile blocker محتمل. فوق ذلك، Flutter يستخدم Socket/REST بينما الويب يستخدم Firestore hooks.
- Matches web intent: لا.
- Status: Broken.
- Main gaps: compile blocker، اختلاف backend path عن الويب، raw Dio/no auth risk، fallback data في ContactHost، وعدم ثبات real-time.

## Trips / Favorites / Wishlists

- هدف القسم في الويب: الرحلات والمفضلة/wishlists تحفظ نشاط المستخدم وتعرض حجوزاته وعقاراته المحفوظة.
- Flutter equivalent: `TripsScreen`, `FavoritesScreen`, `WishlistsScreen`, `FavoritesCubit`, `UserService`.
- Reachable in UI: Trips في bottom nav، favorites/wishlists من profile أو routes.
- Visible to users: نعم جزئيا.
- Actually usable: جزئيا. توجد API calls لبعض القوائم، لكن الرحلة الكاملة تعتمد على booking/payment، وهما غير جاهزين. المفضلة من بعض البطاقات قد تعمل، لكن تفاصيل العقار من `FavoritesScreen` تمرر `arguments: property` بشكل مشابه للمشكلة المحتملة في details route إذا لم يحتوي structure المتوقع.
- Matches web intent: جزئي.
- Status: Partial.
- Main gaps: اعتمادها على booking broken، route args risk، وتجربة wishlists أقل نضجا من الويب.

# 3) Wiring and Reachability Audit

## Home

- Screen exists: نعم، `home_screen.dart`.
- Route exists: نعم عبر bottom nav، وroute constants تشمل home.
- Route registered: home constant ليس route مستقلا واضحا في `AppRoutes`، لكن الشاشة موجودة داخل bottom nav.
- Navigation reaches it: نعم عند بدء التطبيق.
- Cubit/bloc wired: لا يعتمد على Cubit أساسي؛ يستخدم services مباشرة.
- Service wired: `PropertyService`, `UserService`, `UserSession`.
- Real API called: نعم عبر property/user services.
- Loading/error/success: موجود جزئيا.
- Status: Partial.

## Discover / Search

- Screen exists: نعم، `DiscoverScreen`, `PropertiesScreen`, `SearchPropertiesScreen`, `SearchModalScreen`, `AdvancedFiltersScreen`.
- Route exists: نعم لمعظمها.
- Route registered: نعم لمعظم search/discover routes.
- Navigation reaches it: Search tab يصل إلى `PropertiesScreen`; `SearchModal` يصل إلى `SearchPropertiesScreen`.
- Cubit/bloc wired: `SearchCubit` في `SearchPropertiesScreen`; `PropertiesScreen` يستخدم service مباشرة.
- Service wired: `PropertyService`.
- Real API called: نعم، لكن filter values ليست مستخدمة دائما.
- Loading/error/success: موجودة جزئيا.
- Status: Partial.

## Property Details

- Screen exists: نعم.
- Route exists: نعم `Routes.propertyDetails`.
- Route registered: نعم.
- Navigation reaches it: نعم، لكن من `PropertiesScreen` arguments مكسورة.
- Cubit/bloc wired: نعم `PropertyDetailsCubit`.
- Service wired: `PropertyService`, `RatingsService`.
- Real API called: نعم إذا وصل propertyId.
- Loading/error/success: موجودة، لكن initial blank ممكن بسبب missing id.
- Status: Broken من route معين / Partial عموما.

## Booking

- Screen exists: نعم `BookingRequestScreen`, `BookingConfirmationScreen`, `BookingDetailsScreen`.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم من details بعد login.
- Cubit/bloc wired: `BookingCubit`.
- Service wired: `UserService.createBooking`.
- Real API called: نعم.
- Loading/error/success: موجودة جزئيا.
- Status: Partial / Not Release-Ready.

## Payment

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم بعد booking.
- Cubit/bloc wired: services مباشرة أكثر من Cubit.
- Service wired: `PaymentService`, `StripePaymentService`, `PayPalPaymentService`.
- Real API called: نعم، لكن endpoints/tokens/order ids لا تطابق الويب في نقاط حرجة.
- Loading/error/success: موجودة جزئيا.
- Status: Broken.

## Auth

- Screen exists: نعم `LoginScreen`, `SignUpScreen`, forgot/reset.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم من profile auth prompt وguards.
- Cubit/bloc wired: `AuthCubit`.
- Service wired: `ClerkService`, `UserSession`.
- Real API called: نعم، Clerk Frontend API مباشرة.
- Loading/error/success: موجودة جزئيا.
- Status: Partial / Integration Risk.
- ملاحظة parity: الويب يستخدم Clerk SDK و`ClerkTokenSync` مع Bearer token في `api-client.ts`; Flutter يستخدم manual Clerk Frontend API/cookies. هذا اختلاف release-risk.

## Profile / Account

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم لمعظم account screens.
- Navigation reaches it: نعم من bottom profile بعد auth.
- Cubit/bloc wired: بعض الشاشات نعم، وبعضها state محلي.
- Service wired: `UserService`, `UserSession`.
- Real API called: جزئيا.
- Loading/error/success: جزئيا.
- Status: Partial.

## Host

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم من Profile/Home/Host Dashboard.
- Cubit/bloc wired: نعم.
- Service wired: `HostService`, لكن raw Dio/no clear auth.
- Real API called: نعم، لكن parsing/casts مشكوك فيها.
- Loading/error/success: موجودة جزئيا.
- Status: Broken / Not Release-Ready.

## Messages

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم.
- Cubit/bloc wired: متداخل بين `messages` و`chat`.
- Service wired: خطأ في `ConversationsScreen` لأنه يستخدم `UserService` بدلا من `ChatService`.
- Real API called: لا يمكن الاعتماد بسبب compile blocker.
- Loading/error/success: موجودة جزئيا.
- Status: Broken.

## Support

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم.
- Cubit/bloc wired: `SupportCubit`.
- Service wired: `SupportService`.
- Real API called: نعم.
- Loading/error/success: جزئيا.
- Status: Partial.

## Notifications

- Screen exists: نعم.
- Route exists: نعم.
- Route registered: نعم.
- Navigation reaches it: نعم.
- Cubit/bloc wired: `NotificationsCubit`.
- Service wired: `NotificationService`.
- Real API called: نعم.
- Loading/error/success: جزئيا.
- Status: Partial.

## Static Route Gaps

- Constants موجودة وغير مسجلة في `AppRoutes.onGenerateRoute`: `dateSelection`, `guestSelection`, `amenities`, `reviews`, `locationMap`, `profile`, `properties`, `home`.
- `Routes.properties` مستخدم من `ClientDashboardScreen` لكنه غير مسجل كroute مستقل؛ هذا navigation dead end محتمل.
- `SplashScreen` موجود، لكن `lib/app.dart` يبدأ من `Routes.bottomNav` مباشرة، لذلك splash/onboarding/auth restore ليسوا بداية فعلية للتطبيق.

# 4) UI/UX Parity and Product Feel Audit

- الأقرب للويب: Home وSearchProperties وPropertyDetails جزئيا. هذه الشاشات لديها بطاقات، صور، بحث، وعناصر قريبة من rental marketplace.
- غير قريب من الويب: Payment، Host Dashboard، Add Listing، Messages، Personal Info، Support. هذه إما تختلف في التكامل أو أقل عمقا أو بها controls غير فعالة.
- شاشات تبدو قديمة أو غير مصقولة: Notifications بسبب mojibake، ListProperty بسبب نصوص عربية مشوهة، وبعض settings screens بسبب toggles محلية وأزرار لا تفعل شيئا.
- شاشات placeholder أو fake: map في `PropertiesScreen` أقرب إلى عرض بصري وليس خريطة حقيقية؛ attachment في support فارغ؛ حذف الحساب TODO؛ ربط PayPal في profile payment methods يظهر SnackBar "قريبا"؛ بعض recommendation/discover sections مبنية على static data.
- content hierarchy: الويب يضع funnel واضحا: search/filter -> property details -> validated booking -> payment provider. Flutter يكسر continuity بين Search tab والتفاصيل، وبين booking والدفع.
- action hierarchy: في الويب actions المهمة مرتبطة بحالة المستخدم والتوفر والسعر. في Flutter بعض actions ظاهرة بدون guard كاف أو بدون تنفيذ كامل.
- loading/empty/error: موجودة في أجزاء كثيرة، لكنها ليست موحدة. بعض الأخطاء تصبح blank screen أو SnackBar فقط، وبعض الشاشات لا تحول الضيف إلى sign-in بوضوح.
- product feel: ليس موحدا بما يكفي للنشر. هناك mix بين Arabic/English وبعض النصوص مشوهة، وmix بين services مباشرة وCubit، وmix بين REST/Socket/Firestore parity.

# 5) Broken, Fake, Hidden, or Disconnected Areas

- Hidden: `DiscoverScreen` ليس مركز التجربة في bottom nav رغم أن الويب يملك `/discover`.
- Hidden/weak: `PropertyWizardScreen` الأكثر تنظيما موجود، لكن الرحلة الظاهرة تستخدم `ListPropertyScreen` غالبا.
- Disconnected: `Routes.properties` مستخدم لكنه غير مسجل في `AppRoutes`.
- Disconnected: constants مثل `reviews`, `amenities`, `locationMap`, `dateSelection`, `guestSelection` موجودة بدون route registration.
- Broken: `ConversationsScreen` يستدعي `UserService.getConversations` غير الموجود.
- Broken: `PropertiesScreen` يمرر `arguments: p` إلى details، ما قد يجعل details بلا `propertyId`.
- Broken: `HostDashboardCubit` يعمل casts خاطئة من `List<PropertyModel>`/`List<BookingModel>` إلى `List<Map<String,dynamic>>`.
- Broken: `SadadWebViewScreen` يتحقق من الدفع باستخدام `bookingId` بدلا من order/payment id.
- Broken: `PaypalWebViewScreen` يلتقط order مع `userId: ''`.
- Fake/weak: `PropertiesScreen` filter/modal return values لا تطبق.
- Fake/weak: support attachment button بدون implementation.
- Fake/weak: account settings delete account TODO.
- Fake/weak: profile payment PayPal linking "قريبا".
- Structural-only: payment services موجودة لكن لا تتبع نفس web integration path.
- Structural-only: host screens كثيرة لكنها ليست release usable بسبب dashboard/service/wizard issues.
- Structural-only: notifications موجودة لكن auth gating وtext polish غير جاهزين.
- Compile-risk: `auth_interceptor.dart` يستخدم `GlobalKey<NavigatorState>` مع import من `foundation.dart` فقط، ما يحتاج تحقق build فعلي.

# 6) Workflow Usability Audit

## Auth

- Web workflow: Clerk SDK عبر `/sign-in` و`ClerkTokenSync` يجلب token ويحفظه في `localStorage` ويحقنه كBearer في API client.
- Flutter workflow: Login/SignUp custom forms عبر `ClerkService` يتعامل مباشرة مع Clerk Frontend API وcookies، ويحفظ user/session/token في `UserSession`.
- Mismatch: Flutter لا يتبع نفس Clerk SDK/token-sync path. هذا ليس خطأ مؤكدا وحده، لكنه parity/release risk لأن backend في الويب مبني حول Bearer token sync.
- Works end to end: غير مثبت runtime.
- Usable by real user: جزئيا إذا Clerk manual flow يعمل.
- Release-ready: Partial / Integration Risk.

## Search / Discovery

- Web workflow: Home/Discover يستخدمان نفس publicSearchFilter وفلاتر غنية وخريطة/قائمة.
- Flutter workflow: Home list، Search modal إلى SearchProperties، Search tab إلى PropertiesScreen.
- Mismatch: Search tab لا يطبق advanced filter output؛ Discover full غير surfaced؛ map ليست parity.
- Works end to end: جزئيا.
- Usable by real user: جزئيا، لكن تجربة البحث الأساسية غير موثوقة.
- Release-ready: Partial.

## Property Details

- Web workflow: بطاقة عقار -> details كاملة -> booking card validated.
- Flutter workflow: من Home/SearchProperties غالبا يعمل، من PropertiesScreen ينكسر بسبب args.
- Mismatch: availability/ratings loading غير مضمون، booking UX أقل.
- Works end to end: لا من كل المسارات.
- Usable by real user: جزئيا فقط.
- Release-ready: Not Release-Ready.

## Booking

- Web workflow: confirm page يتحقق من السعر والتوفر والضيوف قبل الدفع.
- Flutter workflow: booking request يحسب محليا ثم ينشئ booking.
- Mismatch: لا نفس server-time/availability/pricing validation.
- Works end to end: غير مثبت، ومخاطره عالية.
- Usable by real user: ضعيف.
- Release-ready: Not Release-Ready.

## Payment

- Web workflow: Paymob credit card، PayPal، Sadad، Noqoody.
- Flutter workflow: Stripe، PayPal، Sadad.
- Mismatch: جوهري. طرق الدفع ونقاط النهاية والتحقق لا تطابق الويب.
- Works end to end: غالبا لا.
- Usable by real user: لا يمكن اعتباره آمنا.
- Release-ready: Broken.

## Account / Settings

- Web workflow: حساب غني مع هوية ومدفوعات ومعلومات شخصية متكاملة.
- Flutter workflow: profile menu وعدة settings screens أبسط.
- Mismatch: حقول كثيرة ناقصة وأفعال غير محفوظة.
- Works end to end: جزئيا.
- Usable by real user: جزئيا.
- Release-ready: Partial.

## Host Flow

- Web workflow: dashboard كامل، listings، bookings، calendar، earnings، messages، reviews، add listing.
- Flutter workflow: routes كثيرة، dashboard، list property wizard.
- Mismatch: dashboard crash risk، wizard ضعيف، services/auth غير مثبتة، status/actions ناقصة.
- Works end to end: لا.
- Usable by real host: لا.
- Release-ready: Broken.

## Support

- Web workflow: help/support/contact channels واضحة.
- Flutter workflow: help center + ticket form.
- Mismatch: direct channels ناقصة، attachment fake، guest handling ضعيف.
- Works end to end: جزئيا للمستخدم المسجل.
- Usable by real user: جزئيا.
- Release-ready: Partial.

## Notifications / Chat

- Web workflow: chat real-time Firestore، notifications/account context.
- Flutter workflow: notifications REST، chat Socket/REST، duplicate chat/messages packages.
- Mismatch: messages مكسورة compile-wise ومختلفة عن Firestore path.
- Works end to end: notifications جزئيا؛ chat لا.
- Usable by real user: chat لا؛ notifications جزئيا.
- Release-ready: Chat Broken, Notifications Partial.

# 7) Release Blockers

1. Messages compile/runtime blocker: `ConversationsScreen` يستدعي `UserService.getConversations` غير الموجود.
2. Payment integration غير مطابق للويب: Stripe بدلا من Paymob/Noqoody، endpoints مختلفة، PayPal userId فارغ، Sadad verify يستخدم bookingId.
3. Property details مكسورة من Search tab بسبب `PropertiesScreen` يمرر `arguments: p` لا structure المتوقع.
4. Host dashboard معرض للكسر بسبب casts خاطئة في `HostDashboardCubit`.
5. Booking لا يستخدم نفس availability/pricing/server-time validation مثل الويب.
6. Flutter auth path مختلف عن web Clerk SDK/token sync، ويحتاج إثبات end-to-end قبل release.
7. Search filters في `PropertiesScreen` لا تطبق فعليا رغم ظهور UI.
8. Routes dead/missing registration مثل `Routes.properties` وroute constants أخرى.
9. Splash/onboarding/auth restore ليست launch flow لأن app يبدأ من bottom nav مباشرة.
10. Account/settings فيها actions غير فعالة مثل delete account، 2FA، phone/email edit، وبعض toggles local.
11. Host listing wizard ليس release-grade: validation ضعيف، نصوص مشوهة، host/user association غير واضح، upload غير مثبت.
12. Chat integration لا يتبع web Firestore path ومكسور في wiring.
13. Notifications وListProperty بها mojibake يؤثر على polish والثقة.
14. Support لا يطابق direct support channels في الويب وattachment fake.
15. عدم القدرة على تشغيل أدوات Flutter/Dart محليا للتحقق يترك build/runtime confidence منخفضا.

# 8) If Released Today: What Would Break?

- مستخدم يفتح تبويب Search ثم يضغط عقار قد يرى شاشة تفاصيل فارغة أو غير محملة بسبب تمرير arguments خاطئ.
- مستخدم يحاول الدفع قد يفشل عند مزود الدفع: PayPal capture بدون userId، Sadad verify بمعرف غير صحيح، وغياب Noqoody/Paymob path الموجود في الويب.
- مستخدم يحاول الرسائل قد يواجه build failure أو شاشة لا تعمل بسبب استدعاء service غير موجود.
- مضيف يفتح dashboard قد يواجه crash بسبب cast خاطئ في cubit.
- مضيف يحاول إضافة عقار سيواجه wizard أقل نضجا، نصوص مشوهة، validation ضعيف، وربما فشل upload/create بسبب DTO/auth mismatch.
- مستخدم يحاول الحجز قد يحصل على سعر أو توفر غير مطابق لما يقرره backend لأن Flutter لا يعيد نفس تحقق الويب.
- مستخدم غير مسجل يضغط notifications/support/list home قد يرى أخطاء أو مسارات login غير ناعمة.
- مستخدم يعدل account settings قد يظن أن خياراته محفوظة بينما بعضها local أو بلا action.
- مستخدم يتوقع تجربة الويب في discover/map/filter سيجد تجربة أبسط وأقل اتصالا.
- فريق النشر قد يواجه compile issues قبل الوصول حتى إلى runtime بسبب messages أو imports.

# 9) Top 20 Fixes for Usability and Release Readiness

1. إصلاح compile blockers في messages و`auth_interceptor`.
   - Why: التطبيق لا يمكن نشره إذا لم يبن.
   - Visible impact: الرسائل تفتح بدلا من الفشل.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: wiring/build.

2. توحيد route arguments لتفاصيل العقار.
   - Why: Search tab يكسر رحلة discovery الأساسية.
   - Visible impact: ضغط بطاقة العقار يفتح التفاصيل دائما.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: navigation/flow.

3. إعادة تحميل ratings/availability بعد اكتمال `getPropertyDetails`.
   - Why: التفاصيل يجب أن تعرض availability/reviews فعليا.
   - Visible impact: تفاصيل أكثر اكتمالا.
   - Release impact: high.
   - Urgency: High.
   - Type: wiring/UX.

4. جعل `PropertiesScreen` يطبق نتائج `AdvancedFiltersScreen`.
   - Why: الفلاتر الظاهرة حاليا لا تغير النتائج في المسار الرئيسي.
   - Visible impact: بحث وفلاتر حقيقية.
   - Release impact: high.
   - Urgency: High.
   - Type: UX/API/wiring.

5. توحيد search/discover حول نفس API pattern المستخدم في الويب.
   - Why: web source of truth يستخدم `publicSearchFilter`.
   - Visible impact: نتائج وفلاتر أقرب للويب.
   - Release impact: high.
   - Urgency: High.
   - Type: API/flow.

6. استبدال مسار الدفع في Flutter بمسارات الويب نفسها على app-side.
   - Why: اختلاف الدفع أخطر بلوكر تجاري.
   - Visible impact: دفع يعمل بالطرق المتوقعة.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: integration/API.

7. إضافة Noqoody/Paymob parity وإزالة الاعتماد release-wise على Stripe إذا لم يكن ضمن web checkout.
   - Why: Stripe ليس مسار الويب الحالي.
   - Visible impact: خيارات دفع مطابقة.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: integration/payment.

8. إصلاح PayPal capture بتمرير userId/session الصحيح.
   - Why: capture الحالي يرسل userId فارغ.
   - Visible impact: إتمام PayPal.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: integration.

9. إصلاح Sadad order/payment id lifecycle.
   - Why: verification يستخدم bookingId بدلا من orderId.
   - Visible impact: تأكيد الدفع صحيح.
   - Release impact: critical.
   - Urgency: Critical.
   - Type: integration.

10. جعل booking يستخدم backend availability/pricing validation مثل الويب.
    - Why: يمنع أسعار وتواريخ غير صحيحة.
    - Visible impact: price breakdown موثوق.
    - Release impact: critical.
    - Urgency: Critical.
    - Type: flow/API.

11. إصلاح `HostDashboardCubit` casts ونموذج الحالة.
    - Why: dashboard المضيف معرض للcrash.
    - Visible impact: لوحة المضيف تفتح.
    - Release impact: high.
    - Urgency: High.
    - Type: wiring/runtime.

12. ربط `HostService` بنفس auth/session approach المستخدم في باقي API calls.
    - Why: raw Dio قد يفشل أو يفقد auth.
    - Visible impact: بيانات المضيف تظهر.
    - Release impact: high.
    - Urgency: High.
    - Type: API/auth.

13. جعل wizard المضيف الظاهر هو الأكثر اكتمالا وإضافة validation.
    - Why: إضافة عقار flow رئيسي في المنتج.
    - Visible impact: مضيف يضيف عقار بثقة.
    - Release impact: high.
    - Urgency: High.
    - Type: UX/flow.

14. إصلاح mojibake في Notifications وListProperty.
    - Why: النص المشوه يعطي إحساس تطبيق غير جاهز.
    - Visible impact: polish فوري.
    - Release impact: medium.
    - Urgency: High.
    - Type: UI.

15. جعل profile logout يمسح session فعليا.
    - Why: logout الظاهري يسبب جلسات عالقة.
    - Visible impact: تسجيل خروج موثوق.
    - Release impact: high.
    - Urgency: High.
    - Type: auth/flow.

16. تحويل account settings غير الفعالة إلى actions حقيقية أو إخفائها حتى تكتمل.
    - Why: أزرار لا تفعل شيئا تقلل الثقة.
    - Visible impact: إعدادات صادقة.
    - Release impact: medium.
    - Urgency: Medium.
    - Type: UX/wiring.

17. ربط support بقنوات الويب الواضحة وإصلاح attachment.
    - Why: الدعم مهم للنشر.
    - Visible impact: مستخدم يعرف كيف يطلب مساعدة.
    - Release impact: medium.
    - Urgency: Medium.
    - Type: UX/wiring.

18. توحيد chat على مسار يعمل فعليا ومطابق لفكرة الويب.
    - Why: الرسائل جزء أساسي من marketplace.
    - Visible impact: محادثات حقيقية.
    - Release impact: high.
    - Urgency: High.
    - Type: integration/wiring.

19. تنظيف route registry وربط dead routes أو حذف استخدامها.
    - Why: يمنع navigation dead ends.
    - Visible impact: تنقل متوقع.
    - Release impact: high.
    - Urgency: High.
    - Type: navigation.

20. تشغيل build/analyze/test وتحقيق visual QA على emulator بعد إصلاح build.
    - Why: audit الحالي code-level بسبب تعطل tooling.
    - Visible impact: ثقة قبل النشر.
    - Release impact: critical.
    - Urgency: Critical.
    - Type: release verification.

# 10) Final Verdict

- هل التطبيق قابل للاستخدام فعليا؟ جزئيا فقط. التصفح الأولي ممكن، لكن الرحلات المهمة مثل search-to-details، booking-to-payment، host management، messages ليست موثوقة.
- هل هو مقنع بصريا؟ جزئيا. بعض الشاشات جيدة، لكن النصوص المشوهة، الشاشات غير الفعالة، وضعف parity في discover/payment/host تجعل المنتج غير مقنع كنسخة نشر.
- هل هو جاهز وظيفيا؟ لا.
- هل هو جاهز للنشر؟ لا، وبشكل واضح.
- النسبة التقريبية user-ready: حوالي 35% إلى 45% من التجربة مرئية وقابلة للاستخدام جزئيا.
- النسبة structural/partial/fake/broken: حوالي 55% إلى 65%، مع بلوكرز تجعل readiness الفعلية للنشر صفر حتى إصلاح build/payment/messages/host/details.
- أسرع طريق للنشر: أولا إصلاح build blockers والroute args، ثم جعل search/details/booking/payment تعمل end-to-end بنفس backend behavior الموجود في الويب، ثم تثبيت auth/session، ثم إغلاق host/messages/support/settings gaps، وبعدها تشغيل analyze/test/emulator QA.

# 11) Visual / Runtime Verification Notes

- Runtime verification لم تكن ممكنة بثقة في هذه الجولة.
- تمت محاولة استخدام أدوات Flutter/Dart الأساسية سابقا مثل `flutter --version`, `flutter devices`, و`dart --version` لكنها علقت/انتهت بمهلة، لذلك لم يتم تشغيل التطبيق، لم يتم فتح emulator، ولم يتم التقاط screenshots فعلية.
- الشاشات التي تم تدقيقها: تدقيق كودي لمسارات Home، Search/Discover، Properties، Property Details، Booking، Payment، Auth، Profile/Account، Host، Support، Notifications، Chat/Messages، Trips/Favorites.
- التدفقات التي تم التحقق منها: code-level reachability وwiring فقط، وليس runtime/visual navigation.
- ما لم يمكن التحقق منه: build النهائي، rendered UI، keyboard/form behavior، actual network responses، payment redirects، Firebase/Socket real-time behavior، وemulator device flows.
- تأثير ذلك على الثقة: الثقة عالية في الفجوات الكودية المثبتة بالملفات والمسارات، لكنها أقل في الحكم على التفاصيل البصرية الدقيقة لأن التطبيق لم يعمل أمامنا. مع ذلك، وجود compile/runtime/payment/navigation blockers كاف للحكم أن التطبيق ليس release-ready حاليا.
