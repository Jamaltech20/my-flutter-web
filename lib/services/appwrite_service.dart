import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService {
  // 💡 Remove setTimeout() which is not defined in the newer Client class.
  final Client client = Client(); 
  
  late final Account account;
  late final Databases databases;
  late final Realtime realtime;

  AppwriteService() {
    client
        .setEndpoint('https://sgp.cloud.appwrite.io/v1')
        .setProject('6917829c000e451155f9');

    account = Account(client);
    databases = Databases(client);
    realtime = Realtime(client);
  }

  /// 🔑 Attempts to retrieve a session or create an anonymous session.
  Future<User?> init() async {
    try {
      // 1. Check if the user is already logged in
      return await account.get();
    } on AppwriteException catch (e) {
      // If the error is due to lack of login (e.code == 401), proceed with anonymous login.
      if (e.code == 401) {
        try {
          // 2. Create an anonymous session
          await account.createAnonymousSession();
          // 3. Retrieve the created user's info
          return await account.get();
        } catch (e) {
          print('خطا در ورود ناشناس: $e');
          return null;
        }
      }
      print('خطای عمومی در init: $e');
      return null;
    } catch (e) {
      print('خطای ناشناخته در init: $e');
      return null;
    }
  }

  /// 🚪 Checks if an active user (anonymous or authenticated) session exists.
  Future<bool> isLoggedIn() async {
    try {
      final user = await account.get();
      return user.$id.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}