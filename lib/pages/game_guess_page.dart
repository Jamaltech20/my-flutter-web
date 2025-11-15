import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../services/appwrite_service.dart';
import '../pages/chat_history_page.dart';
import '../widgets/penalty_chat_widget.dart';


class GameGuessPage extends StatefulWidget {
  final String roomCode;
  final List<String> players;
  final String currentPlayerName;
  final String starterName;
  final String documentId;

  const GameGuessPage({
    super.key,
    required this.roomCode,
    required this.players,
    required this.currentPlayerName,
    required this.starterName,
    required this.documentId,
  });

  @override
  State<GameGuessPage> createState() => _GameGuessPageState();
}

class _GameGuessPageState extends State<GameGuessPage> {
  static const String DATABASE_ID = "jamal1_";
  static const String COLLECTION_ID = "rooms";
  static const String CHAT_FIELD_NAME = "chatHistory";

  final AppwriteService appwrite = AppwriteService();
  StreamController<int> wheelController = StreamController<int>.broadcast();
  StreamSubscription? realtimeSub;
  Timer? countdownTimer;
  // ✅ تایمر جدید برای ناپدید شدن پیام موقت
  Timer? _messageDisplayTimer;

  List<int> wheelIndices = List.generate(20, (i) => i);

  int? spinnerResult;
  bool spinnerUsed = true;
  String currentTurnPlayer = "";

  bool isCountingDown = false;
  int countdown = 3;
  bool isDataRefreshing = false;

  // --- State های مدیریت سوال جریمه ---
  bool isPenaltyQuestionActive = false;
  String currentPenaltyQuestion = "";
  String questionWinner = "";
  String? penaltyResponse;
  final TextEditingController _responseController = TextEditingController();
  // ----------------------------------------

  String? chatHistory;
  String? _lastDisplayedMessage;
  int _unreadMessageCount = 0;
  final List<String> penaltyQuestions = [
    // 5 سوال اصلی
    "یک حقیقت جالب در مورد خودت بگو.",
    "اگر می‌توانستی نام خود را عوض کنی، چه نامی انتخاب می‌کردی؟",
    "چیزی که دوست داری در مورد حریفت بدانی، چیست؟",
    "یک کار خنده‌دار انجام بده.",
    "آخرین دروغی که گفتی چه بود.",

    // 70 سوال اضافه شده در پاسخ‌های قبلی
    "بزرگترین رویایی که هنوز به من نگفته‌ای، چیست؟",
    "تصویر تو از زندگی 'کامل' چیست؟",
    "اگر می‌توانستی یک چیز را در جهان تغییر دهی، آن چه بود؟",
    "اهدافی که تا ۵ سال دیگر می‌خواهی به آن‌ها برسی، کدامند؟",
    "اگر برنده یک سفر تفریحی به هر نقطه‌ای در جهان باشیم، کجا را انتخاب می‌کنی؟",
    "یک مهارتی که همیشه دوست داشتی یاد بگیری اما هنوز شروع نکرده‌ای؟",
    "مهم‌ترین چیزی که امیدواریم فرزندانمان (یا نسل بعدی) از ما یاد بگیرند، چیست؟",
    "ترجیح می‌دهی ثروت زیاد داشته باشی یا زمان زیاد؟ چرا؟",
    "یک کسب و کار یا ایده خلاقانه‌ای که دوست داری راه‌اندازی کنی، چیست؟",
    "بزرگترین ریسکی که تا به حال کرده‌ای و ارزشش را داشته، چه بود؟",
    "از نظر تو، مهم‌ترین اختراع بشر چه بوده است؟",
    "یک عادتی که دوست داری آن را ترک کنی و یک عادتی که دوست داری آن را شروع کنی؟",
    "اگر مجبور باشی همه دارایی‌هایت را به جز سه مورد رها کنی، آن سه مورد چه خواهند بود؟",
    "کدام نقش تاریخی یا شخصیت تخیلی را دوست داشتی در دنیای واقعی بازی کنی؟",
    "بزرگترین موفقیتی که در مورد آن هنوز به کسی نگفته‌ای؟",
    "اولین باری که فهمیدی عاشقم هستی/حس خاصی به من داری، چه لحظه‌ای بود؟",
    "بهترین و بدترین خاطره مشترک ما چیست؟",
    "کدام یک از شوخی‌های درونی ما برای تو خنده‌دارتر است؟",
    "دوست داری زبان عشق من به تو بیشتر از چه طریقی ابراز شود؟",
    "چه کاری از من تو را بیش از همه احساس امنیت و آرامش می‌دهد؟",
    "صمیمانه‌ترین تعریفی که تا به حال از من شنیده‌ای، چیست؟",
    "به نظر تو بهترین بخش رابطه‌ ما چیست؟",
    "آیا فکر می‌کنی در بیان احساساتت به من راحت هستی؟ چرا؟",
    "یک قرار ملاقات ایده‌آل برای تو چگونه خواهد بود؟",
    "کدام آهنگ یا فیلم تو را به یاد من می‌اندازد؟",
    "چه چیزی باعث می‌شود احساس کنی که کاملاً توسط من دیده و درک شده‌ای؟",
    "اگر می‌توانستیم یک قانون جدید برای رابطه خود بگذاریم، چه بود؟",
    "چه چیزی در مورد من تو را بیشتر از همه جذب می‌کند (علاوه بر ظاهر)?",
    "دوست داری در آینده چطور با هم در تصمیم‌گیری‌های سخت همکاری کنیم؟",
    "چه چیزی را در مورد روشی که با هم دعوا می‌کنیم یا آشتی می‌کنیم، دوست داری؟",
    "آیا حس می‌کنی که می‌توانی هر چیزی را بدون قضاوت به من بگویی؟",
    "بهترین هدیه‌ای که تا به حال از من گرفته‌ای (مادی یا غیرمادی) چه بوده؟",
    "اگر می‌توانستیم یک روز کاملاً با هم باشیم و هر کاری بخواهیم بکنیم، آن روز را چگونه می‌گذراندیم؟",
    "چه چیزی در مورد من تو را به خنده می‌اندازد؟",
    "اگر نام یک کتاب در مورد داستان عشق ما چه بود؟",
    "عجیب‌ترین چیزی که تا به حال خورده‌ای، چیست؟",
    "اگر می‌توانستی فقط یک غذا را تا آخر عمر بخوری، چه غذایی را انتخاب می‌کردی؟",
    "بدترین مدل مویی که تا به حال داشته‌ای، چه بوده است؟",
    "آخرین باری که آنقدر خندیدی که اشکت درآمد، کی بود و چرا؟",
    "خجالت‌آورترین چیزی که تا به حال برایت اتفاق افتاده، چیست؟",
    "اگر یک ابرقدرت داشتی، آن چه بود؟",
    "اگر می‌توانستی با یک حیوان حرف بزنی، کدام حیوان را انتخاب می‌کردی؟",
    "بهترین عذر و بهانه‌ای که تا به حال برای انجام ندادن کاری آورده‌ای؟",
    "اگر قرار بود در یک مسابقه تلویزیونی شرکت کنی، کدام مسابقه را انتخاب می‌کردی؟",
    "احمقانه‌ترین کاری که با پول انجام داده‌ای، چه بوده است؟",
    "کدام شخصیت کارتونی بیشتر شبیه توست و چرا؟",
    "اگر روح یک خانه بودی، دوست داشتی چه نوع خانه‌ای باشی؟",
    "عجیب‌ترین چیزی که مردم فکر می‌کنند در مورد تو درست است، اما غلط است؟",
    "مهم‌ترین درسی که تا به حال در زندگی گرفته‌ای، چیست؟",
    "چه چیزی برایت در زندگی بیشترین معنا و اهمیت را دارد؟",
    "بزرگترین ترسی که هنوز بر آن غلبه نکرده‌ای، چیست؟",
    "از کدام یک از عادت‌های روزانه‌ات بیشتر از همه لذت می‌بری؟",
    "سه کلمه‌ای که دوستانت برای توصیف تو استفاده می‌کنند، چیست؟",
    "چه چیزی تو را در برابر ناملایمات قوی نگه می‌دارد؟",
    "کدام کتاب، فیلم یا مستند زندگی تو را تغییر داده است؟",
    "یک چیزی که مردم اغلب درباره‌اش سوءتفاهم دارند؟",
    "ترجیح می‌دهی در جمع باشی یا تنها؟",
    "اگر می‌دانستی که فردا خواهی مرد، امروز چه کاری انجام می‌دادی؟",
    "مهم‌ترین چیزی که به خودت در سال‌های اخیر بخشیده‌ای (فهم، آرامش، فرصت و...) چه بوده است؟",
    "بزرگترین منتقد زندگی تو کیست؟",
    "بهترین خاطره تو از دوران کودکی چیست؟",
    "کدام معلم بیشترین تأثیر را بر زندگی تو گذاشت و چرا؟",
    "محبوب‌ترین کارتون یا برنامه تلویزیونی تو در دوران کودکی چه بود؟",
    "یک چیزی که از والدینت یاد گرفتی و همیشه با تو مانده است؟",
    "چه چیزی را در مورد بزرگ شدن (بزرگسال بودن) بیشتر از همه دوست داری؟",
    "ترسناک‌ترین چیزی که در کودکی تجربه کرده‌ای؟",
    "کدام خاطره برای تو مثل یک مکان امن است که همیشه می‌توانی به آن برگردی؟",
    "یک مکان از گذشته که دلت برایش تنگ شده است؟",
    "احمقانه‌ترین چیزی که در کودکی به آن اعتقاد داشتی، چه بود؟",
    "کدام یک از جشن‌های سنتی یا تعطیلات برای تو معنای عمیق‌تری دارد؟",

    // 125 سوال جدید
    "اگر می‌توانستی یک روز را به عنوان فرد دیگری زندگی کنی، چه کسی را انتخاب می‌کردی؟",
    "اگر ۱۰۰ میلیون دلار برنده می‌شدی، اولین کاری که می‌کردی چه بود؟",
    "اگر می‌توانستی با یک فرد مشهور (زنده یا مرده) شام بخوری، چه کسی را انتخاب می‌کردی؟",
    "چه چیزی را هرگز حاضر نیستی فدای پول یا موفقیت کنی؟",
    "سخت‌ترین تصمیم اخلاقی که تا به حال گرفته‌ای، چه بوده است؟",
    "ترجیح می‌دهی در آینده ناشناخته باشی و شاد زندگی کنی، یا مشهور باشی و کمی ناراحت؟",
    "اگر می‌توانستی به یک سال خاص در تاریخ سفر کنی، کدام سال را انتخاب می‌کردی؟",
    "چه چیزی را به عنوان 'بزرگترین ضعف' خود می‌بینی؟",
    "اگر دنیا را برای یک روز رهبری می‌کردی، اولین قانون تو چه بود؟",
    "ترجیح می‌دهی بدترین دروغگو باشی یا بدترین حافظه را داشته باشی؟",
    "یک مهارت بقا که دوست داری در آن استاد باشی؟",
    "اگر مجبور بودی خانه را فوراً ترک کنی، سه شیئی که برمی‌داشتی چه بودند؟",
    "ترجیح می‌دهی آینده را بدانی یا گذشته را تغییر دهی؟",
    "چه توصیه‌ای به نسخه ۱۰ سال پیش خودت می‌کنی؟",
    "یک قانون اجتماعی یا فرهنگی که فکر می‌کنی باید حذف شود؟",
    "اگر می‌توانستی یک کار هنری (نقاشی، مجسمه، آهنگ) خلق کنی که تا ابد باقی بماند، چه چیزی می‌بود؟",
    "کدام یک از اختراعات مدرن زندگی را بیش از همه آسان کرده است؟",
    "آیا همیشه حقیقت را می‌گویی، حتی اگر آزاردهنده باشد؟",
    "چه چیزی تو را واقعاً عصبانی می‌کند؟",
    "یک کتاب یا فیلم که حس می‌کنی همه باید آن را ببینند؟",
    "بهترین راه برای گذراندن یک صبح آرام برای تو چیست؟",
    "مورد علاقه‌ترین نوع موسیقی یا پادکستی که در حال حاضر به آن گوش می‌دهی؟",
    "از چه غذایی در منوی رستوران‌ها همیشه سفارش می‌دهی؟",
    "خنده‌دارترین یا عجیب‌ترین چیزی که در کیف یا جیبت حمل می‌کنی؟",
    "عادت ناخوشایندی که سعی می‌کنی پنهانش کنی؟",
    "کدام یک از کارهای خانه برایت سخت‌ترین و کدام لذت‌بخش‌ترین است؟",
    "ترجیح می‌دهی شب‌زنده دار باشی یا سحرخیز؟",
    "یک مکانی که دوست داری هر سال به آن سفر کنی؟",
    "بزرگترین ولخرجی که تا به حال کرده‌ای، چه بوده است؟",
    "چه چیزی باعث می‌شود احساس کنی که کاملاً 'در خانه' هستی؟",
    "کدام یک از دوستان تو بیشترین تأثیر را بر شخصیتت داشته است؟",
    "ترجیح می‌دهی یک توانایی خارق‌العاده داشته باشی یا یک ظاهر خارق‌العاده؟",
    "آیا به سرنوشت اعتقاد داری یا فکر می‌کنی زندگی کاملاً در کنترل خود ماست؟",
    "بهترین توصیه‌ای که یک فرد غریبه به تو داده است؟",
    "یک غذایی که از آن متنفری اما جرأت نمی‌کنی به کسی بگویی؟",
    "ترجیح می‌دهی در کوه زندگی کنی یا کنار دریا؟",
    "چقدر در برنامه‌ریزی روزانه‌ات انعطاف‌پذیر هستی؟",
    "بهترین و بدترین لباس‌هایی که تا به حال پوشیده‌ای؟",
    "یک شیئی که همیشه با خود حمل می‌کنی و برایت معنی خاصی دارد؟",
    "چه چیزی تو را از نظر روحی آرام می‌کند؟",
    "سه کلمه‌ای که خودت را با آن‌ها توصیف می‌کنی، چیست؟",
    "یک مهارتی که فکر می‌کنی باید در آن بهتر شوی؟",
    "کدام ویژگی شخصیتی تو اغلب توسط دیگران سوءتفاهم می‌شود؟",
    "چه چیزی باعث می‌شود احساس کنی در مسیر درست زندگی قرار داری؟",
    "آیا از ریسک کردن می‌ترسی؟",
    "بزرگترین منبع انرژی یا الهام‌بخش تو کیست؟",
    "چه چیزی تو را به گریه می‌اندازد؟",
    "کدام کلمه یا عبارت را بیش از حد استفاده می‌کنی؟",
    "بهترین درسی که از شکست خورده‌ای؟",
    "یک چیزی که در مورد خودت دوست نداری اما یاد گرفته‌ای بپذیری؟",
    "بهترین لحظه‌ای که تا به حال به خودت افتخار کرده‌ای؟",
    "آیا ترجیح می‌دهی از عقل پیروی کنی یا از قلب؟",
    "چه نوع میراثی را دوست داری در این دنیا از خودت به جا بگذاری؟",
    "مهم‌ترین عنصری که در دوستی به دنبال آن هستی، چیست؟",
    "یک باور رایج که تو آن را رد می‌کنی؟",
    "چطور با استرس کنار می‌آیی؟",
    "آیا فکر می‌کنی بیشتر به گذشته، حال، یا آینده فکر می‌کنی؟",
    "یک کاری که دیگران فکر می‌کنند سخت است اما برای تو آسان است؟",
    "چه چیزی تو را در یک رابطه احساس امنیت می‌دهد؟",
    "یک عادت کوچک که فکر می‌کنی کیفیت زندگی تو را بهتر کرده است؟",
    "ترجیح می‌دهی کاری انجام دهی که به آن اعتقاد داری، یا کاری که بابت آن پول زیادی بگیری؟",
    "کدام ویژگی شخصیتی من را بیشتر از همه تحسین می‌کنی؟",
    "یک چیزی که در مورد خودت هست که دوست داری همه بدانند؟",
    "آیا خودت را یک فرد خوش‌بین می‌دانی یا بدبین؟",
    "چه کاری را باید در این ماه متوقف کنی؟",
    "نام حیوان خانگی مورد علاقه‌ات در کودکی (اگر داشتی) چه بود؟",
    "خجالت‌آورترین چیزی که در مدرسه یا یک مکان عمومی به زبان آوردی؟",
    "بدترین بلایی که سر یکی از خواهر و برادرهایت (اگر داری) آوردی؟",
    "یک بازی دوران کودکی که هنوز هم از انجام آن لذت می‌بری؟",
    "چه شغل رویایی در دوران کودکی داشتی؟",
    "بهترین اسباب بازی یا شیء مورد علاقه‌ات در کودکی چه بود؟",
    "کدام یک از داستان‌ها یا افسانه‌های کودکی برایت ترسناک یا عجیب بود؟",
    "یک کار جسورانه‌ای که در کودکی انجام دادی؟",
    "اولین چیزی که به یاد می‌آوری برایت 'بزرگترین' هدیه بود؟",
    "یک مهارت یا سرگرمی که در کودکی شروع کردی اما دیگر دنبال نکردی؟",
    "چه چیزی در کودکی باعث می‌شد احساس کنی بالغ شده‌ای؟",
    "یک چیزی که دوست داری از دوران کودکی به زندگی الان برگردانی؟",
    "بزرگترین تنبیهی که تا به حال گرفته‌ای، چه بود؟",
    "کدام نوع غذا تو را به یاد دوران کودکی‌ات می‌اندازد؟",
    "یک آرزوی بچگانه که هنوز هم به شکلی در تو باقی مانده است؟",
    "آیا فکر می‌کنی ما تنها موجودات هوشمند در جهان هستیم؟",
    "اگر می‌توانستی یک کتاب درسی را از نظام آموزشی حذف کنی، کدام بود؟",
    "با ارزش‌ترین زمان در زندگی تو چه زمانی است؟",
    "چه چیزی باعث می‌شود که به کسی اعتماد کنی؟",
    "آیا تا به حال یک تجربه فراطبیعی یا توضیح‌ناپذیر داشته‌ای؟",
    "ترجیح می‌دهی نامرئی باشی یا بتوانی پرواز کنی؟",
    "کدام عادتمان را بیش از همه دوست داری و کدام را باید تغییر دهیم؟",
    "اگر قرار بود در یک جزیره دورافتاده زندگی کنی، سه نفر را برای همراهی با خودت انتخاب می‌کردی؟",
    "یک دروغ کوچکی که اغلب می‌گویی؟",
    "بهترین و بدترین فیلمی که اخیراً دیده‌ای؟",
    "چه چیزی تو را متواضع می‌کند؟",
    "آیا خودت را فردی هنری می‌دانی یا علمی؟",
    "دوست داری بدانی چه زمانی می‌میری یا چگونه؟",
    "یک چیزی که در مورد من دوست داری اما فکر می‌کنی من خودم نمی‌دانم؟",
    "یک شغلی که هرگز انجام نمی‌دهی؟",
    "اگر یک شعار شخصی داشتی، چه بود؟",
    "چه زمانی برای اولین بار احساس کردی یک بزرگسال هستی؟",
    "آیا تا به حال به چیزی اعتقاد داشتی که بعداً فهمیدی اشتباه است؟",
    "چه چیزی تو را از نظر روحی تغذیه می‌کند؟",
    "کدام یک از نقاط قوت تو اغلب نادیده گرفته می‌شود؟",
    "یک کاری که دوست داری در دوران پیری با هم انجام دهیم؟",
    "اگر یک پیام جهانی داشتی، آن چه بود؟",
    "چه چیزی تو را به خاطر می‌آورد که چقدر شانس آورده‌ای؟",
    "کدام یک از فضیلت‌ها برایت مهم‌ترین است (صداقت، وفاداری، شجاعت و...)?",
    "بزرگترین پشیمانی زندگی تو چیست؟",
    "ترجیح می‌دهی در آب و هوای سرد زندگی کنی یا گرم؟",
    "یک کاری که فکر می‌کنی در آن واقعاً خوب هستی؟",
    "اگر می‌توانستی با خودِ ۲۰ سال پیشت صحبت کنی، چه می‌گفتی؟",
    "کدام یک از حیوانات بیشتر از همه تو را توصیف می‌کند؟",
    "بهترین و بدترین ویژگی شخصیتی من از نظر تو؟",
    "چه چیزی تو را از انجام کاری که می‌خواهی باز می‌دارد؟",
    "اگر می‌دانستی که نمی‌توانی شکست بخوری، چه ریسکی می‌کردی؟",
    "سخت‌ترین عادتی که ترک کردی؟",
    "بهترین درس غیرمنتظره‌ای که از کسی یاد گرفته‌ای؟",
    "آیا خودت را یک فرد درونگرا می‌دانی یا برونگرا؟",
    "مهم‌ترین دارایی تو چیست؟ (مادی یا غیرمادی)",
    "کدام یک از حس‌های تو (بینایی، بویایی، شنوایی و...) برایت مهم‌ترین است؟",
    "آیا فکر می‌کنی ما در یک واقعیت شبیه‌سازی شده زندگی می‌کنیم؟",
    "چه نوع میراثی را دوست داری برای خانواده‌ات به جا بگذاری؟",
    "یک کاری که انجام می‌دهی و از آن متنفر هستی، اما باید انجامش دهی؟",
    "بهترین و بدترین عادت پولی تو چیست؟",
    "بزرگترین تحولی که در شخصیتت در ۱۰ سال اخیر داشته‌ای؟",
    "اگر می‌توانستی یک کار معجزه‌آسا انجام دهی، چه کاری می‌کردی؟",
    "زیباترین کلمه‌ای که می‌شناسی چیست؟",
    "سه آرزوی صادقانه که برای من داری، چیست؟"
];

  @override
  void initState() {
    super.initState();
    _listenRealtime();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshWheel().then((_) {
        if (spinnerResult == null &&
            widget.currentPlayerName == currentTurnPlayer &&
            !spinnerUsed &&
            !isPenaltyQuestionActive) {
          _spinWheelWithCountdown();
        }
      });
    });
  }

  void _listenRealtime() {
    realtimeSub = appwrite.realtime
        .subscribe(["databases.$DATABASE_ID.collections.$COLLECTION_ID.documents.${widget.documentId}"])
        .stream
        .listen((event) {
          final data = event.payload;

          currentTurnPlayer = data["currentPlayer"] ?? currentTurnPlayer;
          spinnerUsed = data["spinnerUsed"] ?? spinnerUsed;

          final newResult = data["spinnerResult"];

          if (newResult != null) {
            if (newResult != spinnerResult) {
              spinnerResult = newResult;
              wheelController.add(spinnerResult!);
            }
          } else {
            spinnerResult = null;
          }

          isPenaltyQuestionActive = data["penaltyQuestionActive"] ?? false;
          currentPenaltyQuestion = data["currentQuestion"] ?? "";
          questionWinner = data["questionWinner"] ?? "";
          penaltyResponse = data["penaltyResponse"];

          // ✅ توجه: فیلد chatHistory ممکن است در آپدیت‌های سیستمی خالی باشد یا تغییری نکند.
          final newChatHistory = data[CHAT_FIELD_NAME] as String?;
          final newUnreadCount = data["unreadMessageCount"] as int? ?? 0;
          
          // ⚠️ فقط در صورتی که chatHistory تغییر کرده یا یک سیگنال Realtime جدید (با unreadCount جدید) رسیده باشد، پردازش را انجام دهید.
          if (newChatHistory != chatHistory || newUnreadCount != _unreadMessageCount) {
            chatHistory = newChatHistory;
            _unreadMessageCount = newUnreadCount;
            // 💡 برای نمایش پیام موقت (شامل پیام‌های سیستمی جریمه) آخرین پیام را پردازش کنید.
            _processLastChatMessage(data[CHAT_FIELD_NAME] as String?, event.payload);
          }
          
          if (isCountingDown) {
            countdownTimer?.cancel();
            isCountingDown = false;
          }

          setState(() {});
    });
  }

  // ✅ تابع نمایش پیام چت عمومی و پیام‌های سیستمی جریمه (اصلاح شده)
  void _processLastChatMessage(String? newHistory, Map<String, dynamic> realtimePayload) {
      _messageDisplayTimer?.cancel(); // تایمر قبلی را لغو کنید
      
      // 1. ابتدا پیام‌های سیستمی جریمه را از payload Realtime چک می‌کنیم (بخش ذخیره شده شما).
      final String? penaltySignal = realtimePayload["penaltySignal"] as String?;
      
      // 👇 اصلاح: استفاده از contains برای اطمینان از تشخیص پیام سیگنال جریمه
      if (penaltySignal != null) {
        // پیام سیگنال برای نمایش موقت به حریف
        String displayContent = "";
        // استفاده از contains برای نادیده گرفتن [سیستم] در ابتدای پیام
        if (penaltySignal.contains("حریف حریمه را انحام داد")) {
          displayContent = "انجام داد";
        } else if (penaltySignal.contains("حریف حریمه را انحام نداد")) {
          displayContent = "انجام نداد";
        }
        
        if (displayContent.isNotEmpty) {
          setState(() {
            _lastDisplayedMessage = "حریف ($displayContent)"; // نمایش موقت برای حریف
          });
          // 🕒 تنظیم تایمر ۵ ثانیه‌ای برای ناپدید شدن پیام موقت (مطابق درخواست شما)
          _messageDisplayTimer = Timer(const Duration(seconds: 5), () {
            setState(() {
              _lastDisplayedMessage = null;
            });
          });
          // 🛑 پس از نمایش پیام جریمه، ادامه ندهید
          return;
        }
      }

      // 2. اگر سیگنال جریمه‌ای نبود، پیام‌های عادی چت را پردازش کنید.
      if (newHistory == null || newHistory.isEmpty) {
          // اگر چت خالی شد و پیام موقت جریمه‌ای در کار نبود، پیام موقت را پاک کن
          setState(() {
              _lastDisplayedMessage = null;
          });
          return;
      }

      List<String> messages = newHistory.split('\n').where((s) => s.isNotEmpty).toList();

      if (messages.isNotEmpty) {
          String fullMessage = messages.last;

          String senderName = "سیستم";
          String content = fullMessage;

          if (fullMessage.startsWith('[') && fullMessage.contains('] ')) {
              int endBracket = fullMessage.indexOf(']');
              senderName = fullMessage.substring(1, endBracket);
              content = fullMessage.substring(endBracket + 2);
          }

          // 🛑 پیام‌های سیستمی (اگر به هر دلیلی در چت باشند) نمایش داده نمی‌شوند.
          if (senderName == "سیستم") {
              setState(() { _lastDisplayedMessage = null; });
              return;
          } 
          
          // پیام‌های عادی بازیکنان
          String displaySender = (senderName == widget.currentPlayerName) ? "شما" : "حریف";
          setState(() {
              _lastDisplayedMessage = "$displaySender ($content)";
          });
          

          // 🕒 تنظیم تایمر ۵ ثانیه‌ای برای ناپدید شدن پیام موقت
          if (_lastDisplayedMessage != null) {
            _messageDisplayTimer = Timer(const Duration(seconds: 5), () {
              setState(() {
                _lastDisplayedMessage = null;
              });
            });
          }
      }
  }

  @override
  void dispose() {
    realtimeSub?.cancel();
    wheelController.close();
    countdownTimer?.cancel();
    _messageDisplayTimer?.cancel(); // ❌ لغو تایمر هنگام خروج از صفحه
    _responseController.dispose();
    super.dispose();
  }

  String _getTextForIndex(int index) {
    bool isEven = index % 2 == 0;
    return widget.currentPlayerName == widget.starterName
        ? (isEven ? "شما" : "حریف")
        : (isEven ? "حریف" : "شما");
  }

  Future<void> _resetSpinState() async {
    await appwrite.databases.updateDocument(
      databaseId: DATABASE_ID,
      collectionId: COLLECTION_ID,
      documentId: widget.documentId,
      data: {"spinnerResult": null, "spinnerUsed": false},
    );
  }

  Future<void> _spinWheelWithCountdown() async {
    if (widget.currentPlayerName != currentTurnPlayer || spinnerUsed || isCountingDown || isPenaltyQuestionActive) return;

    await _resetSpinState();
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() {
      isCountingDown = true;
      countdown = 3;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isCountingDown = false;
        });
        _finalizeSpin();
      }
    });
  }

  Future<void> _finalizeSpin() async {
    int randomIndex = Random().nextInt(wheelIndices.length);
    final String winnerText = _getTextForIndex(randomIndex);

    final String actualWinnerName = winnerText == "شما"
        ? widget.currentPlayerName
        : widget.players.firstWhere(
            (player) => player != widget.currentPlayerName,
            orElse: () => widget.currentPlayerName
        );

    await appwrite.databases.updateDocument(
      databaseId: DATABASE_ID,
      collectionId: COLLECTION_ID,
      documentId: widget.documentId,
      data: {
        "spinnerResult": randomIndex,
        "spinnerUsed": true,
      },
    );

    await Future.delayed(const Duration(seconds: 5));

    final Random random = Random();
    final String selectedQuestion = penaltyQuestions[random.nextInt(penaltyQuestions.length)];

    await appwrite.databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
        data: {
          "penaltyQuestionActive": true,
          "currentQuestion": selectedQuestion,
          "questionWinner": actualWinnerName,
          "penaltyResponse": null,
        },
    );
  }

  // ✅ تابع ارسال پاسخ جریمه (بدون تغییر)
  Future<void> _sendPenaltyResponse() async {
    final responseText = _responseController.text.trim();
    if (responseText.isEmpty || responseText.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("پیام باید بین ۱ تا ۵۰ حرف باشد.")),
      );
      return;
    }

    final doc = await appwrite.databases.getDocument(
      databaseId: DATABASE_ID,
      collectionId: COLLECTION_ID,
      documentId: widget.documentId,
    );
    final currentResponse = doc.data["penaltyResponse"] as String? ?? "";

    final newResponse = currentResponse.isEmpty
        ? responseText
        : "$currentResponse\n$responseText";

    await appwrite.databases.updateDocument(
      databaseId: DATABASE_ID,
      collectionId: COLLECTION_ID,
      documentId: widget.documentId,
      data: {
        "penaltyResponse": newResponse,
      },
    );
    _responseController.clear();
  }

  // 🛑 تابع اصلاح شده برای افزودن پیام به چت - **پیام‌های سیستمی جریمه را ذخیره نمی‌کند.**
  Future<void> _addChatMessage(String message) async {
    // 🛑 پیام‌های سیستمی نباید در تاریخچه چت ذخیره شوند.
    final bool isSystemMessage = message.startsWith("[سیستم]");

    final doc = await appwrite.databases.getDocument(
      databaseId: DATABASE_ID,
      collectionId: COLLECTION_ID,
      documentId: widget.documentId,
    );

    final currentChat = doc.data[CHAT_FIELD_NAME] as String? ?? "";
    final currentUnreadCount = doc.data["unreadMessageCount"] as int? ?? 0;
    
    final Map<String, dynamic> updateData = {
      // همیشه unreadMessageCount را افزایش می‌دهیم تا realtime حریف فعال شود
      "unreadMessageCount": currentUnreadCount + 1, 
    };

    if (!isSystemMessage) {
      // اگر پیام از طرف سیستم نیست، آن را به تاریخچه چت اضافه کنید.
      final String formattedMessage = "[${widget.currentPlayerName}] $message";

      final newChat = currentChat.isEmpty
          ? formattedMessage
          : "$currentChat\n$formattedMessage";

      updateData[CHAT_FIELD_NAME] = newChat;
    } else {
      // ⚠️ اگر پیام سیستمی است، فقط سیگنال را در فیلد موقت "penaltySignal" می‌گذاریم.
      // فیلد CHAT_FIELD_NAME (chatHistory) دستکاری نمی‌شود.
      updateData["penaltySignal"] = message; 
    }


    await appwrite.databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
        data: updateData
    );
  }

  // ✅ تابع هندل کردن پایان جریمه (اصلاح‌شده نهایی)
  Future<void> _handlePenaltyAnswer(bool completed) async {
    final String nextTurnPlayer;
    
    // 1. پیام‌های دقیق و اصلاح‌شده برای سیگنال Realtime به حریف
    // این پیام در فیلد penaltySignal ذخیره می‌شود و در تاریخچه چت قرار نمی‌گیرد.
    final String chatAndOpponentMessage = completed
        ? "[سیستم] حریف حریمه را انحام داد" 
        : "[سیستم] حریف حریمه را انحام نداد"; 

    // 2. پیام شخصی‌سازی شده برای نمایش در SnackBar خودی (۳ ثانیه)
    final String selfDisplayMessage = completed
        ? "شما انجام دادید"
        : "شما انجام ندادید";


    // 3. تعیین نوبت بعدی
    if (completed) {
      nextTurnPlayer = questionWinner; // برنده نوبت را حفظ می‌کند
    } else {
      // نوبت به حریف برنده جریمه می‌رسد
      final opponent = widget.players.firstWhere(
        (player) => player != questionWinner,
        orElse: () => questionWinner
      );
      nextTurnPlayer = opponent;
    }

    // 4. ارسال پیام سیگنال به دیتابیس (فقط برای فعال شدن Realtime و نمایش موقت ۵ ثانیه‌ای)
    await _addChatMessage(chatAndOpponentMessage);

    // 5. نمایش پیام ۳ ثانیه‌ای (SnackBar) در پایین صفحه (مطابق با درخواست قبلی شما)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(selfDisplayMessage),
        duration: const Duration(seconds: 3),
        backgroundColor: completed ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );

    // 6. به‌روزرسانی وضعیت اتاق برای پایان جریمه
    await appwrite.databases.updateDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
        data: {
          "currentPlayer": nextTurnPlayer,
          "spinnerResult": null,
          "spinnerUsed": false,
          "penaltyQuestionActive": false,
          "currentQuestion": null,
          "questionWinner": null,
          "penaltyResponse": null,
          "penaltySignal": null, // ✅ سیگنال را پس از پایان جریمه پاک کنید.
        },
    );
  }

  Future<void> _refreshWheel() async {
    setState(() {
      isDataRefreshing = true;
    });

    try {
      final doc = await appwrite.databases.getDocument(
        databaseId: DATABASE_ID,
        collectionId: COLLECTION_ID,
        documentId: widget.documentId,
      );

      final data = doc.data;
      currentTurnPlayer = data['currentPlayer'] ?? widget.starterName;
      spinnerResult = data['spinnerResult'];
      spinnerUsed = data['spinnerUsed'] ?? true;

      isPenaltyQuestionActive = data['penaltyQuestionActive'] ?? false;
      currentPenaltyQuestion = data['currentQuestion'] ?? "";
      questionWinner = data['questionWinner'] ?? "";
      penaltyResponse = data["penaltyResponse"];

      chatHistory = data[CHAT_FIELD_NAME] as String?;
      _unreadMessageCount = data["unreadMessageCount"] as int? ?? 0;
      // 💡 در _refreshWheel هم باید سیگنال جریمه چک شود.
      _processLastChatMessage(chatHistory, data); 

      if (spinnerResult != null) {
        wheelController.add(spinnerResult!);
      } else {
        spinnerResult = null;
      }

    } catch (e) {
      print("Error refreshing data: $e");
    } finally {
      setState(() {
        isDataRefreshing = false;
        isCountingDown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enableSpinButton = widget.currentPlayerName == currentTurnPlayer &&
                                 !spinnerUsed &&
                                 !isCountingDown &&
                                 !isDataRefreshing &&
                                 !isPenaltyQuestionActive;

    final bool isPlayerTheQuestionWinner = isPenaltyQuestionActive && questionWinner == widget.currentPlayerName;
    final bool enableAnswerButtons = isPlayerTheQuestionWinner;

    final List<String> messages = penaltyResponse != null
        ? penaltyResponse!.split('\n').where((s) => s.isNotEmpty).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        actions: [
          // دکمه چت با نشان (Badge)
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.message),
                if (_unreadMessageCount > 0)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadMessageCount > 9 ? '9+' : '$_unreadMessageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
              ],
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryPage(
                    currentChatHistory: chatHistory,
                    documentId: widget.documentId,
                    currentPlayerName: widget.currentPlayerName,
                    initialUnreadCount: _unreadMessageCount,
                  ),
                ),
              );

              if (result != null && result is String) {
                setState(() {
                  chatHistory = result;
                });
                // ⚠️ در اینجا باید با اطلاعات کامل دیتابیس مجدداً چت را پردازش کنیم یا به _refreshWheel بسپاریم
                // برای سادگی فعلا همان منطق قبلی را حفظ می کنیم:
                _processLastChatMessage(chatHistory, {}); 
              }
            },
            tooltip: "چت عمومی (${_unreadMessageCount > 0 ? '$_unreadMessageCount پیام جدید' : 'بدون پیام جدید'})",
          ),
          IconButton(
            icon: isDataRefreshing
                ? const Icon(Icons.sync)
                : const Icon(Icons.refresh),
            onPressed: isDataRefreshing ? null : _refreshWheel,
            tooltip: "رفرش وضعیت",
          ),
        ],

        title: Text("بازی حدس - اتاق ${widget.roomCode}"),
        backgroundColor: Colors.blueGrey,

        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String result) {
            if (result == 'خروج') {
              // منطق بازگشت به صفحه قبل (GuessRoom)
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("گزینه $result انتخاب شد.")),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'تنظیمات',
              child: Text('تنظیمات'),
            ),
            const PopupMenuItem<String>(
              value: 'خروج',
              child: Text('خروج از بازی'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // نمایش آخرین پیام چت
            if (_lastDisplayedMessage != null && !isPenaltyQuestionActive)
                Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, left: 16, right: 16),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.lightBlue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5))
                        ),
                        child: Text(
                            "💬 $_lastDisplayedMessage",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.blueGrey,
                                overflow: TextOverflow.ellipsis
                            ),
                            maxLines: 1,
                        ),
                    ),
                ),

            // --- نمایش پیام وضعیت نوبت عادی (اگر جریمه فعال نباشد) ---
            if (!isPenaltyQuestionActive)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  !spinnerUsed && spinnerResult == null
                      ? isCountingDown
                          ? "🔄 شمارش معکوس: **$countdown**"
                          : widget.currentPlayerName == currentTurnPlayer
                              ? "نوبت **شما** است، گردونه را بچرخانید."
                              : "منتظر نوبت **$currentTurnPlayer** باشید..."
                      : spinnerUsed && spinnerResult != null
                          ? "✅ گردونه در حال چرخیدن"
                          : isDataRefreshing
                              ? "در حال بارگذاری..."
                              : "در انتظار شروع نوبت...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isCountingDown ? Colors.red : Colors.indigo
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),

            // --- نمایش سوال جریمه با استفاده از ویجت جداگانه ---
            if (isPenaltyQuestionActive)
                PenaltyChatWidget(
                  isPlayerTheQuestionWinner: isPlayerTheQuestionWinner,
                  currentPenaltyQuestion: currentPenaltyQuestion,
                  messages: messages,
                  responseController: _responseController,
                  onSendPenaltyResponse: _sendPenaltyResponse,
                  enableAnswerButtons: enableAnswerButtons,
                  onAnswerCompleted: () => _handlePenaltyAnswer(true),
                  onAnswerNotCompleted: () => _handlePenaltyAnswer(false),
                )
            else
              SizedBox(
                height: 300,
                child: FortuneWheel(
                  selected: wheelController.stream,
                  duration: const Duration(seconds: 5),
                  animateFirst: false,
                  items: [
                    for (int index in wheelIndices)
                      FortuneItem(
                        child: Text(
                          _getTextForIndex(index),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: enableSpinButton ? _spinWheelWithCountdown : null,
              child: Text(isCountingDown ? "در حال شمارش..." : "چرخش گردونه"),
            ),
            const SizedBox(height: 20),

            if (spinnerResult != null && !spinnerUsed && !isPenaltyQuestionActive)
              Text(
                "🎯 نتیجه: ${_getTextForIndex(spinnerResult!)}",
                style: const TextStyle(fontSize: 22),
              ),
          ],
        ),
      ),
    );
  }
}