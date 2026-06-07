/// Actions that require a signed-in backend user.
enum AuthGatedAction {
  generateVideo,
  uploadImage,
  saveToLibrary,
  shareVideo,
  subscribePremium,
  profileFeatures,
}

extension AuthGatedActionCopy on AuthGatedAction {
  String get modalTitle {
    switch (this) {
      case AuthGatedAction.generateVideo:
      case AuthGatedAction.uploadImage:
        return 'Create Your First AI Video';
      case AuthGatedAction.saveToLibrary:
        return 'Save Your Creations';
      case AuthGatedAction.shareVideo:
        return 'Share Your AI Video';
      case AuthGatedAction.subscribePremium:
        return 'Unlock Premium';
      case AuthGatedAction.profileFeatures:
        return 'Personalize Your Profile';
    }
  }

  String get modalSubtitle {
    switch (this) {
      case AuthGatedAction.generateVideo:
      case AuthGatedAction.uploadImage:
        return 'Sign in to generate videos, save creations, and unlock premium AI tools.';
      case AuthGatedAction.saveToLibrary:
        return 'Sign in to save videos to your library and access them on any device.';
      case AuthGatedAction.shareVideo:
        return 'Sign in to share your AI videos and grow your audience.';
      case AuthGatedAction.subscribePremium:
        return 'Sign in to subscribe, sync purchases, and unlock premium features.';
      case AuthGatedAction.profileFeatures:
        return 'Sign in to edit your profile, sync videos, and manage your account.';
    }
  }
}
