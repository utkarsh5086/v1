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
import UserNotifications


// MARK: - ContentView

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


struct TitleScreen: View {
    @State private var showingSignUp = false
    @State private var showingSignIn = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("VoteBase")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your personalized election hub")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // MARK: - Sign Up Button (sheet)
            Button(action: { showingSignUp = true }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }

            // MARK: - Sign In Button (sheet)
            Button(action: { showingSignIn = true }) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }

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
    @AppStorage("userAddress") private var userAddress = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("userEmail") private var userEmail = ""


    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var gender = "Male"
    @State private var address = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var signupError: String?

    @Environment(\.presentationMode) private var presentationMode

    private let genders = ["Male", "Female", "Other"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Sign Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { g in Text(g) }
                    }
                    .pickerStyle(.segmented)

                    TextField("Address", text: $address)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Toggle(isOn: $notificationsEnabled) {
                        Text("Turn on notifications")
                    }
                    .padding()
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                DispatchQueue.main.async {
                                    if !granted { notificationsEnabled = false }
                                }
                            }
                        }
                    }

                    if let signupError = signupError {
                        Text(signupError)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        } else {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isLoading)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func signUp() {
        guard !name.isEmpty, !address.isEmpty, !email.isEmpty, !password.isEmpty else {
            signupError = "Please fill in all fields."
            return
        }

        isLoading = true
        signupError = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dobString = formatter.string(from: dateOfBirth)

        let requestBody = SignUpRequest(
            name: name,
            date_of_birth: dobString,
            gender: gender,
            address: address,
            email: email,
            password: password
        )

        guard let url = URL(string: "http://127.0.0.1:8000/users") else {
            signupError = "Invalid server URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do { request.httpBody = try JSONEncoder().encode(requestBody) } 
        catch { signupError = "Failed to encode request."; isLoading = false; return }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    signupError = "Sign up failed: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    signupError = "No response from server."
                    return
                }
                do {
                    let result = try JSONDecoder().decode(SignUpResponse.self, from: data)
                    if result.success {
                        // ✅ Use the address user entered
                        userAddress = address
                        hasCompletedSignup = true

                        // Dismiss sheet to reveal ContentView
                        presentationMode.wrappedValue.dismiss()
                        userEmail = email
                        print("Sign up completed successfully")
                    } else {
                        signupError = result.message ?? "Sign up failed."
                    }
                } catch {
                    signupError = "Failed to decode server response."
                }
            }
        }.resume()
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


// MARK: - Navigation Destinations
enum BottomBarDestination: Hashable {
    case search
    case detail(Int)
    case profile   // <- new
}





// MARK: - SearchView
struct SearchView: View {
    @Binding var path: NavigationPath
    @State private var address: String = ""
    @State private var elections: [Election] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TextField("Enter address", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Search") { fetchElections() }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                if isLoading { ProgressView().padding() }

                List(elections, id: \.id) { election in
                    Button {
                        path.append(BottomBarDestination.detail(election.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(election.name).font(.headline)
                            Text("Date: \(election.date)").font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
                .padding(.bottom, 80)
            }

            VStack {
                Spacer()
                BottomBar(path: $path)
            }
        }
        .navigationTitle("Search Elections")
        .navigationBarTitleDisplayMode(.inline)
    }

    func fetchElections() {
        guard !address.isEmpty else { return }
        isLoading = true
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://127.0.0.1:8000/elections?address=\(encodedAddress)"
        //let urlString = "http://172.20.10.2:8000/elections?address=\(encodedAddress)"
        guard let url = URL(string: urlString) else { isLoading = false; return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { isLoading = false }
            if let error = error { print("Error:", error); return }
            guard let data = data else { return }

            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ElectionResponse.self, from: data)
                DispatchQueue.main.async { self.elections = result.elections }
            } catch { print("Failed to decode JSON:", error) }
        }.resume()
    }
}

// MARK: - SignInView

struct SignInView: View {
    @AppStorage("hasCompletedSignup") private var hasCompletedSignup = false
    @AppStorage("userAddress") private var userAddress = ""
    @AppStorage("userEmail") private var userEmail = ""


    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var signinError: String?

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Email & Password
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                // Error message
                if let signinError = signinError {
                    Text(signinError)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                // Sign In Button
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            signinError = "Please enter email and password."
            return
        }

        isLoading = true
        signinError = nil

        let requestBody = SignInRequest(email: email, password: password)
        guard let url = URL(string: "http://127.0.0.1:8000/users/signin") else {
            signinError = "Invalid server URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do { request.httpBody = try JSONEncoder().encode(requestBody) } 
        catch { signinError = "Failed to encode request."; isLoading = false; return }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    signinError = "Sign in failed: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    signinError = "No response from server."
                    return
                }

                do {
                    let result = try JSONDecoder().decode(SignInResponse.self, from: data)
                    if result.success, let addr = result.address {
                        userAddress = addr
                        hasCompletedSignup = true // triggers RootView to show ContentView

                        // Dismiss sheet after successful sign in
                        presentationMode.wrappedValue.dismiss()
                        userEmail = email
                        print("Sign in completed successfully")
                    } else {
                        signinError = result.message ?? "Invalid email or password."
                    }
                } catch {
                    signinError = "Failed to decode server response."
                }
            }
        }.resume()
    }
}

// MARK: - ElectionDetailView



// MARK: - Root View

struct RootView: View {
    @AppStorage("hasCompletedSignup") private var hasCompletedSignup = false

    var body: some View {
        if hasCompletedSignup {
            ContentView()
        } else {
            TitleScreen()  // <- no NavigationStack here
        }
    }
}

// MARK: - Election Detail View
struct ElectionDetailView: View {
    let electionId: Int
    @Binding var path: NavigationPath

    @State private var detail: ElectionDetailResponse?
    @State private var expandedRaces: Set<Int> = []
    @State private var expandedCandidates: [Int: Int?] = [:]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let detail = detail {
                        Text(detail.election.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        Text("Date: \(detail.election.date)")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 10)

                        ForEach(detail.races, id: \.id) { race in
                            RaceView(
                                race: race,
                                expandedRaces: $expandedRaces,
                                expandedCandidates: $expandedCandidates
                            )
                        }
                    } else {
                        ProgressView("Loading election...")
                            .padding()
                    }
                }
                .padding(.bottom, 80)
            }

            VStack {
                Spacer()
                BottomBar(path: $path)
            }
        }
        .navigationTitle(detail?.election.name ?? "Election")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchElectionDetail() }
    }

    func fetchElectionDetail() async {
        guard let url = URL(string: "http://127.0.0.1:8000/elections/\(electionId)") else { return }
        //guard let url = URL(string: "http://172.20.10.2:8000/elections/\(electionId)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ElectionDetailResponse.self, from: data)
            DispatchQueue.main.async { self.detail = decoded }
        } catch {
            print("Failed to fetch election detail:", error)
        }
    }
}


enum Destination: Hashable {
    case title      // the app's title screen
    case home
    case search
    case electionDetail(Int)
}


struct ContentView: View {
    @AppStorage("userAddress") private var savedAddress = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var address: String = ""
    @State private var elections: [Election] = []
    @State private var isLoading: Bool = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack(spacing: 0) {
                    if !address.isEmpty {
                        Text("Address: \(address)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    List(elections, id: \.id) { election in
                        HStack {
                            Button {
                                path.append(BottomBarDestination.detail(election.id))
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(election.name).font(.headline)
                                    Text("Date: \(election.date)").font(.subheadline).foregroundColor(.secondary)
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
                    .padding(.bottom, 80)
                }

                VStack {
                    Spacer()
                    BottomBar(path: $path)
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
            .navigationDestination(for: BottomBarDestination.self) { destination in
                switch destination {
                case .search:
                    SearchView(path: $path)
                case .detail(let electionId):
                    ElectionDetailView(electionId: electionId, path: $path)
                case .profile:                           // <- handle Profile
                    ProfileView(path: $path)
                }
            }
        }
    }

    // MARK: - Fetch Elections
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

    URLSession.shared.dataTask(with: url) { data, _, error in
        DispatchQueue.main.async { isLoading = false }
        if let error = error { 
            print("Error fetching elections:", error)
            return 
        }
        guard let data = data else { return }

        do {
            let decoder = JSONDecoder()
            

            let result = try decoder.decode(ElectionResponse.self, from: data)

            // Detect new elections
            let newElections = result.elections.filter { newElection in
                !self.elections.contains(where: { $0.id == newElection.id })
            }

            // Send notifications for new elections
            if !newElections.isEmpty {
                for election in newElections {
                    sendNotification(
                        title: "New Election Available",
                        body: "\(election.name) on \(election.date)"
                    )
                }
            }

            // Update state with latest elections
            DispatchQueue.main.async { self.elections = result.elections }

        } catch {
            print("Failed to decode JSON:", error)
        }
    }.resume()
}


    // MARK: - Calendar
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
                guard let startDate = formatter.date(from: startDateString) else { return }
                let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
                let event = EKEvent(eventStore: eventStore)
                event.title = election.name
                event.startDate = startDate
                event.endDate = endDate
                event.calendar = eventStore.defaultCalendarForNewEvents ?? eventStore.calendars(for: .event).first
                do { try eventStore.save(event, span: .thisEvent) } 
                catch { print("Failed to save event:", error) }
            }
        }
    }

    // MARK: - Local Notifications
    func sendNotification(title: String, body: String) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Updated BottomBar
struct BottomBar: View {
    @Binding var path: NavigationPath
    @AppStorage("hasCompletedSignup") private var hasCompletedSignup = false

    var body: some View {
        HStack {
            BottomBarButton(icon: "house.fill", title: "Home", color: .blue) {
                path = NavigationPath()
            }

            BottomBarButton(icon: "magnifyingglass", title: "Search", color: .blue) {
                path.append(BottomBarDestination.search)
            }

            BottomBarButton(icon: "person.crop.circle", title: "Profile", color: .blue) {
                path.append(BottomBarDestination.profile)
            }

            BottomBarButton(icon: "arrow.backward.circle", title: "Log Out", color: .red) {
                hasCompletedSignup = false
                path = NavigationPath()
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea(edges: .bottom))
    }
}

struct BottomBarButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
        }
    }
}
