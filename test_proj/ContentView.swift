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
    @AppStorage("userAddress") private var savedAddress = ""
    @State private var address: String = ""
    @State private var elections: [Election] = []
    @State private var isLoading: Bool = false

    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        ZStack {
            // MARK: - Main Content
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding()
                }

                List(elections, id: \.id) { election in
                    HStack {
                        NavigationLink(
                            destination: ElectionDetailView(electionId: election.id)
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(election.name)
                                    .font(.headline)

                                Text("Date: \(election.date)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("Time: \(election.start_time ?? "TBD") - \(election.end_time ?? "TBD")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("\(election.races_count ?? 0) Races • \(election.measures ?? 0) Measures")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                        }

                        Spacer()

                        Button {
                            addElectionToCalendar(election)
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .listStyle(.plain)
                .padding(.bottom, 160) // space for input + bottom bar
            }

            // MARK: - Floating Address Input
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Address where you are registered to vote")
                        .font(.headline)

                    HStack {
                        TextField(
                            "Street, City, State, ZIP",
                            text: $address
                        )
                        .textFieldStyle(.roundedBorder)

                        Button("Search") {
                            fetchElections()
                            hideKeyboard()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(14)
                .shadow(radius: 4)
                .padding(.horizontal)
                .padding(.bottom, keyboard.keyboardHeight > 0
                         ? keyboard.keyboardHeight + 70
                         : 70)
                .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
            }

            // MARK: - Bottom Bar
            VStack {
                Spacer()
                BottomBar()
            }
        }
        .navigationTitle("Your Upcoming Elections")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
    if address.isEmpty && !savedAddress.isEmpty {
        address = savedAddress
        fetchElections()
    }
}

    }

    // MARK: - Helpers

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    func fetchElections() {
        guard !address.isEmpty else { return }
        isLoading = true

        let encodedAddress =
            address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString =
            "http://127.0.0.1:8000/elections?address=\(encodedAddress)"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
            }

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
        }
        .resume()
    }

    func addElectionToCalendar(_ election: Election) {
        let eventStore = EKEventStore()

        eventStore.requestAccess(to: .event) { granted, _ in
            guard granted else { return }

            DispatchQueue.main.async {
                let startTime = election.start_time ?? "09:00"
                let startDateString = "\(election.date) \(startTime)"

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd h:mm a"
                formatter.locale = Locale(identifier: "en_US_POSIX")

                guard let startDate = formatter.date(from: startDateString) else {
                    return
                }

                let endDate =
                    Calendar.current.date(byAdding: .hour, value: 1, to: startDate)
                    ?? startDate.addingTimeInterval(3600)

                let event = EKEvent(eventStore: eventStore)
                event.title = election.name
                event.startDate = startDate
                event.endDate = endDate
                event.calendar =
                    eventStore.defaultCalendarForNewEvents
                    ?? eventStore.calendars(for: .event).first

                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch {
                    print("Failed to save event:", error)
                }
            }
        }
    }
}

// MARK: - ExpandableCard
struct ExpandableCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let subtitle: String?
    let isParty: Bool
    let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        if let subtitle = subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(isParty ? partyColor(subtitle) : .secondary)
                                .fontWeight(.semibold)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.gray)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )

            // Content
            if isExpanded {
                VStack(spacing: 8) {
                    content() // ✅ must return View
                }
                .padding(.leading, 16)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}



// MARK: - ElectionDetailView with Bottom Bar
struct ElectionDetailView: View {
    let electionId: Int

    @State private var detail: ElectionDetailResponse?
    @State private var expandedRaces: Set<Int> = []
    @State private var expandedCandidates: [Int: Int?] = [:]

    var body: some View {
        ZStack {
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let detail = detail {
                        // Header
                        Text(detail.election.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        Text("Date: \(detail.election.date)")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 10)

                        // Races
                        ForEach(detail.races, id: \.id) { race in
                            RaceView(
                                race: race,
                                expandedRaces: $expandedRaces,
                                expandedCandidates: $expandedCandidates
                            )
                        }

                        // Election Preparation Buttons
                        ElectionPreparationButtons()
                            .padding(.bottom, 20)
                    } else {
                        ProgressView("Loading election...")
                            .padding()
                    }
                }
                .padding(.bottom, 80) // Prevent content from being hidden by bottom bar
            }

            // Persistent Bottom Bar
            VStack {
                Spacer()
                BottomBar()
            }
        }
        .navigationTitle(detail?.election.name ?? "Election")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchElectionDetail()
        }
    }

    // MARK: - Fetch Election Detail
    func fetchElectionDetail() async {
        guard let url = URL(string: "http://127.0.0.1:8000/elections/\(electionId)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ElectionDetailResponse.self, from: data)
            DispatchQueue.main.async {
                self.detail = decoded
            }
        } catch {
            print("Failed to fetch election detail:", error)
        }
    }
}


// MARK: - Race View
struct RaceView: View {
    let race: Race
    @Binding var expandedRaces: Set<Int>
    @Binding var expandedCandidates: [Int: Int?]

    var body: some View {
        ExpandableCard(
            title: race.race_name,
            isExpanded: Binding(
                get: { expandedRaces.contains(race.id) },
                set: { newValue in
                    if newValue {
                        expandedRaces.insert(race.id)
                    } else {
                        expandedRaces.remove(race.id)
                        expandedCandidates[race.id] = nil
                    }
                }
            ),
            subtitle: "Term: \(race.term ?? 0) yrs • Candidates: \(race.num_candidates)",
            isParty: false
        ) {
            VStack(spacing: 8) {
                ForEach(race.candidates, id: \.id) { candidate in
                    CandidateView(
                        candidate: candidate,
                        raceId: race.id,
                        expandedCandidates: $expandedCandidates
                    )
                }
            }
        }
    }
}

// MARK: - Candidate View
struct CandidateView: View {
    let candidate: Candidate
    let raceId: Int
    @Binding var expandedCandidates: [Int: Int?]

    var body: some View {
        ExpandableCard(
            title: candidate.name,
            isExpanded: Binding(
                get: { expandedCandidates[raceId] == candidate.id },
                set: { newValue in
                    if newValue {
                        expandedCandidates[raceId] = candidate.id
                    } else {
                        expandedCandidates[raceId] = nil
                    }
                }
            ),
            subtitle: candidate.party,
            isParty: true
        ) {
            VStack(alignment: .leading, spacing: 6) {
                if let description = candidate.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text("No description available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Election Preparation Buttons
struct ElectionPreparationButtons: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Election Preparation")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)

            Button(action: {
                if let url = URL(string: "https://www.voteamerica.com/polling-place") {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Polling Locations", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            Button(action: {
                if let url = URL(string: "https://www.nass.org/can-I-vote") {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Check Voter Registration", systemImage: "person.crop.circle.badge.checkmark")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Party Color Helper
func partyColor(_ party: String?) -> Color {
    switch party?.lowercased() {
    case "democratic", "democrat", "d":
        return .blue
    case "republican", "r":
        return .red
    case "independent", "i":
        return .green
    default:
        return .gray
    }
}

// MARK: - BottomBar
struct BottomBar: View {
    let icons = ["house", "magnifyingglass", "calendar", "star", "bell", "person"]
    let labels = ["Home", "Search", "Calendar", "Favorites", "Alerts", "Profile"]
    @State private var selectedIndex = 0
    
    var body: some View {
        HStack {
            ForEach(0..<6) { index in
                Button(action: {
                    selectedIndex = index
                    print("Tapped \(labels[index])")
                    // Add navigation or action here
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: icons[index])
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedIndex == index ? .blue : .gray)
                        Text(labels[index])
                            .font(.caption2)
                            .foregroundColor(selectedIndex == index ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).shadow(radius: 2))
    }
}


struct RootView: View {
    @AppStorage("hasCompletedSignup") private var hasCompletedSignup = false

    var body: some View {
        NavigationStack {
            if hasCompletedSignup {
                ContentView()
            } else {
                TitleScreen()
            }
        }
        .id(hasCompletedSignup) // 🔥 resets navigation when value changes
    }
}


struct TitleScreen: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("Welcome to VoteHelper")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Stay informed about elections and voting.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            NavigationLink(destination: SignUpView()) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button("Info") {
                print("Info tapped")
            }
            .padding(.bottom)

            Spacer()
        }
        .padding()
    }
}

struct SignUpView: View {
    @AppStorage("hasCompletedSignup") private var hasCompletedSignup = false
    // your @State fields stay the same
    //@Environment(\.dismiss) var dismiss
    @AppStorage("userAddress") private var userAddress = ""
    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var gender = "Prefer not to say"

    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // all your form fields here...
                Group {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    DatePicker(
                        "Date of Birth",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )

                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // MARK: - Address
                Group {
                    TextField("Street Address", text: $address)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        TextField("City", text: $city)
                            .textFieldStyle(.roundedBorder)

                        TextField("State", text: $state)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }

                    TextField("ZIP Code", text: $zip)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                Divider()

                // MARK: - Account Info
                Group {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                Button("Sign Up") {
                    signUp()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
        }
    }

    func signUp() {
    // Basic validation can come later

    let fullAddress = "\(address), \(city), \(state) \(zip)"
    userAddress = fullAddress

    hasCompletedSignup = true
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


