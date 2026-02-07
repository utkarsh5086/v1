//
//  ContentView.swift
//  test_proj
//
//  Created by Utkarsh Sharma on 1/29/26.
//

import SwiftUI
import Combine

import EventKit
import EventKitUI

struct ContentView: View {
    @State private var address: String = ""
    @State private var elections: [Election] = []
    @State private var isLoading: Bool = false

    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    List(elections, id: \.id) { election in
                        HStack {
                            NavigationLink(destination: ElectionDetailView(electionId: election.id)) {
                                VStack(alignment: .leading) {
                                    Text(election.name).bold()
                                    Text("Date: \(election.date)")
                                    Text("Time: \(election.start_time ?? "TBD") - \(election.end_time ?? "TBD")")
                                    Text("\(election.races_count ?? 0) Races, \(election.measures ?? 0) Measures")
                                }
                                .padding(.vertical, 4)
                            }

                            Spacer()

                            Button {
                                addElectionToCalendar(election)
                            } label: {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.title2)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // 👈 important
                        }
                    }
                    .padding(.bottom, 120 + keyboard.keyboardHeight)
                }

                // Bottom floating input
                VStack {
                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address where you are registered to vote")
                            .font(.headline)

                        HStack {
                            TextField("Street, City, State, ZIP", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Search") {
                                fetchElections()
                                hideKeyboard()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.bottom, keyboard.keyboardHeight > 0 ? keyboard.keyboardHeight - 20 : 20)
                    .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
                }
            }
            .navigationTitle("Your Upcoming Elections")
            .navigationBarTitleDisplayMode(.inline)

        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }



    // MARK: - API Call
    func fetchElections() {
        guard !address.isEmpty else { return }
        isLoading = true
        
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://127.0.0.1:8000/elections?address=\(encodedAddress)"
        //let urlString = "http://172.20.10.2:8000/elections?address=\(encodedAddress)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            if let error = error {
                print("Error fetching elections:", error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ElectionResponse.self, from: data)
                DispatchQueue.main.async {
                    self.elections = result.elections
                }
            } catch {
                print("Failed to decode JSON:", error)
            }
        }.resume()
    }
    func addElectionToCalendar(_ election: Election) {
        let eventStore = EKEventStore()

        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else {
                print("Calendar access denied")
                return
            }

            DispatchQueue.main.async {
                let startTime = election.start_time ?? "09:00"
                let startDateString = "\(election.date) \(startTime)"

                let formatter = DateFormatter()
                // Adjust format based on your API
                formatter.dateFormat = "yyyy-MM-dd h:mm a"
                formatter.locale = Locale(identifier: "en_US_POSIX")

                guard let startDate = formatter.date(from: startDateString) else {
                    print("❌ Invalid date: \(startDateString)")
                    return
                }

                let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)

                let event = EKEvent(eventStore: eventStore)
                event.title = election.name
                event.startDate = startDate
                event.endDate = endDate
                event.calendar = eventStore.defaultCalendarForNewEvents ?? eventStore.calendars(for: .event).first

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("✅ Election added on \(startDate)")
                } catch {
                    print("❌ Failed to save event:", error)
                }
            }
        }
    }
}



struct ElectionDetailView: View {
    let electionId: Int
    @State private var detail: ElectionDetailResponse?
    @State private var electionName: String = "" // dynamic title

    var body: some View {
        VStack {
            List {
                if let detail = detail {

                    // MARK: - RACES
                    Section(header: Text("Races")) {
                        ForEach(detail.races, id: \.id) { race in
                            NavigationLink(destination: RaceDetailView(race: race)) {
                                VStack(alignment: .leading) {
                                    Text(race.race_name)
                                        .font(.headline)

                                    if let term = race.term {
                                        Text("Term: \(term) years")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Text("\(race.num_candidates) Candidates")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // MARK: - MEASURES
                    if !detail.measures.isEmpty {
                        Section(header: Text("Ballot Measures")) {
                            ForEach(detail.measures, id: \.id) { measure in
                                NavigationLink(
                                    destination: MeasureDetailView(measure: measure)
                                ) {
                                    VStack(alignment: .leading) {
                                        Text(measure.title)
                                            .font(.headline)

                                        Text(measure.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }

                } else {
                    ProgressView("Loading ...")
                }
            }

            // MARK: - Election Preparation Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Election Preparation")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(action: openPollingLocations) {
                        Label("Polling Locations", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: checkVoterRegistration) {
                        Label("Check Voter Registration", systemImage: "person.crop.circle.badge.checkmark")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(electionName.isEmpty ? "Election" : electionName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchElectionDetail()
        }
    }

    // MARK: - Actions
    func openPollingLocations() {
        if let url = URL(string: "https://www.voteamerica.com/polling-place") {
            UIApplication.shared.open(url)
        }
    }

    func checkVoterRegistration() {
        if let url = URL(string: "https://www.nass.org/can-I-vote") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Fetch Election Detail
    func fetchElectionDetail() async {
        guard let url = URL(string: "http://127.0.0.1:8000/elections/\(electionId)") else { return }
        //guard let url = URL(string: "http://172.20.10.2:8000/elections/\(electionId)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ElectionDetailResponse.self, from: data)

            DispatchQueue.main.async {
                self.detail = decoded
                self.electionName = decoded.election.name
            }
        } catch {
            print("Failed to fetch election detail:", error)
        }
    }
}




struct RaceDetailView: View {
    let race: Race

    var body: some View {
        List {
            Section(header: Text("Candidates")) {
                ForEach(race.candidates, id: \.id) { candidate in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            if let description = candidate.description {
                                Text(description)
                            } else {
                                Text("No description available.")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(partyColor(candidate.party))
                                .frame(width: 10, height: 10)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.name)
                                    .font(.headline)

                                if let party = candidate.party {
                                    Text(party)
                                        .font(.subheadline)
                                        .foregroundColor(partyColor(party))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(race.race_name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

func partyColor(_ party: String?) -> Color {
    switch party?.lowercased() {
    case "democratic", "democrat", "D":
        return .blue
    case "republican", "R":
        return .red
    case "independent", "I":
        return .green
    default:
        return .gray
    }
}



final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification
        )
        let willHide = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification
        )

        willShow
            .merge(with: willHide)
            .compactMap { notification -> CGFloat? in
                if notification.name == UIResponder.keyboardWillShowNotification {
                    return (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                } else {
                    return 0
                }
            }
            .assign(to: &$keyboardHeight)
    }
}


