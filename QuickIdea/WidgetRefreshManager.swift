import Foundation
import WidgetKit

/// Widget 刷新管理器
class WidgetRefreshManager {
    static let shared = WidgetRefreshManager()

    private init() {}

    /// 刷新所有 Widget
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 刷新指定 Widget
    func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
