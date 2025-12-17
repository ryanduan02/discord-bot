import Foundation
import EventKit

// MARK: - JSON Models

struct DayEvents: Encodable {
    let date: String          // YYYY-MM-DD in local timezone
    let events: [EventItem]
}

struct EventItem: Encodable {
    let title: String
    let start: String?        // ISO8601 (nil for all-day if you prefer)
    let end: String?          // ISO8601
    let allDay: Bool
    let location: String?
}

func iso8601(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: date)
}

func yyyyMMddLocal(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = .current
    f.timeZone = .current
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)

store.requestFullAccessToEvents { granted, error in
    defer { sem.signal() }

    if let error = error {
        fputs("Error requesting access: \(error)\n", stderr)
        exit(1)
    }
    guard granted else {
        fputs("Calendar access was not granted. Enable it in System Settings > Privacy & Security > Calendars.\n", stderr)
        exit(2)
    }

    let cal = Calendar.current
    let startOfDay = cal.startOfDay(for: Date())
    let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!

    let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
    let ekEvents = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

    let items: [EventItem] = ekEvents.map { e in
        let title = e.title ?? "(No title)"
        let loc = (e.location?.isEmpty == false) ? e.location : nil

        if e.isAllDay {
            return EventItem(title: title, start: nil, end: nil, allDay: true, location: loc)
        } else {
            return EventItem(title: title, start: iso8601(e.startDate), end: iso8601(e.endDate), allDay: false, location: loc)
        }
    }

    let payload = DayEvents(date: yyyyMMddLocal(startOfDay), events: items)

    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // keep it compact for piping
        let data = try encoder.encode(payload)
        print(String(data: data, encoding: .utf8) ?? "{}")
    } catch {
        fputs("Error encoding JSON: \(error)\n", stderr)
        exit(3)
    }
}

_ = sem.wait(timeout: .distantFuture)
