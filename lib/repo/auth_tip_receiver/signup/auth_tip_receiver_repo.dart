//lib\repo\auth_tip_receiver_repo.dart

abstract class AuthTipReceiverRepo {
  Future<void> signUp(String mobileNumber);
}
