import Foundation
import AppKit
import UniformTypeIdentifiers

class DataPortalManager {
    static let shared = DataPortalManager()
    
    private let exportKeys = [
        "buddyOpacity",
        "isBuddyVisible",
        "showAura",
        "appLanguage",
        "preferredBrowser",
        "meetingCountdownThreshold",
        "isInsomniaEnabled",
        "sessionsHistory",
        "quickNotes"
    ]
    
    func exportData() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "blinky_data.json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                var exportDict: [String: Any] = [:]
                
                for key in self.exportKeys {
                    if let value = UserDefaults.standard.object(forKey: key) {
                        exportDict[key] = value
                    }
                }
                
                do {
                    let data = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
                    try data.write(to: url)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    func importData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        for (key, value) in dict {
                            UserDefaults.standard.set(value, forKey: key)
                        }
                        UserDefaults.standard.synchronize()
                        
                        // Notify managers to refresh their data
                        DispatchQueue.main.async {
                            // This would ideally be handled by observing UserDefaults or a custom notification
                            // For simplicity, we can tell the user to restart or try to trigger reloads
                            NotificationCenter.default.post(name: NSNotification.Name("BlinkyDataImported"), object: nil)
                        }
                    }
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }
}
