import Foundation
import EventKit

func formatDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .none
    f.timeStyle = .short
    return f.string(from: date)
}

let store = EKEventStore()

let sem = DispatchSemaphore(value: 0)
store.requestFullAccessToEvents { granted, error in
    if let error = error {
        fputs("Error requesting access: \(error)\n", stderr)
        exit(1)
    }
    guard granted else {
        fputs("Calendar access was not granted. Enable it in System Settings > Privacy & Security > Calendars.\n", stderr)
        exit(2)
    }

    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
    let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

    if events.isEmpty {
        print("No events today.")
    } else {
        for e in events {
            let allDay = e.isAllDay ? " (all-day)" : ""
            let start = e.isAllDay ? "All day" : formatDate(e.startDate)
            let end = e.isAllDay ? "" : "–\(formatDate(e.endDate))"
            let loc = (e.location?.isEmpty == false) ? " @ \(e.location!)" : ""
            print("\(start)\(end)\(allDay): \(e.title ?? "(No title)")\(loc)")
        }
    }
    sem.signal()
}

_ = sem.wait(timeout: .distantFuture)
