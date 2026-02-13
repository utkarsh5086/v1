import SwiftUI

struct ProfileView: View {
    @Binding var path: NavigationPath
    @AppStorage("userAddress") private var userAddress = ""
    @AppStorage("userEmail") private var userEmail = ""   // save email at sign in/signup

    @State private var profile: UserProfile?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Loading profile...")
            } else if let profile = profile {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(profile.name)").font(.headline)
                    Text("Email: \(profile.email)").font(.subheadline)
                    Text("DOB: \(profile.date_of_birth)").font(.subheadline)
                    Text("Gender: \(profile.gender)").font(.subheadline)
                    Text("Address: \(profile.address)").font(.subheadline)
                }
                .padding()
            } else if let error = error {
                Text(error).foregroundColor(.red)
            } else {
                Text("No profile data")
            }

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchProfile() }
    }

    func fetchProfile() async {
        guard !userEmail.isEmpty else { return }

        isLoading = true
        error = nil

        // Example backend endpoint
        //let urlString = "http://127.0.0.1:8000/users/by_email?email=\(userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        let urlString = "http://172.20.10.2:8000/users/by_email?email=\(userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else {
            isLoading = false
            error = "Invalid URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
            DispatchQueue.main.async {
                profile = decoded
                userAddress = decoded.address   // update AppStorage in case it changed
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
