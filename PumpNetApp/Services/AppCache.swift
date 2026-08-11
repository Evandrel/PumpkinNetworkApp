import Foundation

enum AppCache {
    static let articleFeedKey = "cachedWordPressArticleFeed.v1"
    static let didClearNotification = Notification.Name("AppCache.didClear")

    static func clear() {
        UserDefaults.standard.removeObject(forKey: articleFeedKey)
        URLCache.shared.removeAllCachedResponses()
        NotificationCenter.default.post(name: didClearNotification, object: nil)
    }
}
