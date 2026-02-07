//
//  CalenderHelper.swift
//  test_proj
//
//  Created by Utkarsh Sharma on 1/31/26.
//

import EventKit

class CalendarHelper {
    private let eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, _ in
            completion(granted)
        }
    }

    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date
    ) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        return event
    }

    func saveEvent(_ event: EKEvent) throws {
        try eventStore.save(event, span: .thisEvent, commit: true)
    }
}

