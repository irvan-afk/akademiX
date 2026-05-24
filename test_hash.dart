import 'package:bcrypt/bcrypt.dart';

void main() {
  try {
    String hash = '\$2b\$10\$5O/dDAABnb2z3iY2VKv3JOTlE7vD1eZF0UXLr.zkcUYelQtTrPRNG';
    print("Testing checkpw...");
    bool match = BCrypt.checkpw('somepassword', hash);
    print("Match: \$match");
  } catch (e) {
    print("Exception caught: \$e");
  }
}
