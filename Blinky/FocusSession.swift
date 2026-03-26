import Foundation
import SwiftData

@Model
final class FocusSession {
    enum SessionType: String, Codable {
        case focus
        case meeting
    }
    
    @Attribute(.unique) var id: UUID
    var date: Date
    var goal: String
    var durationInMinutes: Int
    var type: SessionType
    
    init(id: UUID = UUID(), date: Date = Date(), goal: String, durationInMinutes: Int, type: SessionType = .focus) {
        self.id = id
        self.date = date
        self.goal = goal
        self.durationInMinutes = durationInMinutes
        self.type = type
    }
}
