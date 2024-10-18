import SwiftUI

// MARK: - Model for Login Request and Response
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let username: String
    let token: String
}

// MARK: - ViewModel for handling Login Logic
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var token: String?  // Store the JWT token

    func login() {
        guard let url = URL(string: "http://localhost:8089/public/login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = LoginRequest(username: username, password: password)
        
        do {
            let jsonData = try JSONEncoder().encode(loginData)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode login data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to login: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                DispatchQueue.main.async {
                    self.token = loginResponse.token  // Store the JWT token
                    self.username = loginResponse.username  // Update username from the response
                    self.isLoggedIn = true
                    print("Login successful. Token: \(loginResponse.token)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode response"
                }
            }
        }.resume()
    }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    TextField("Username", text: $viewModel.username)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                Button(action: {
                    viewModel.login()
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                // Pass both username and token to UserHomeView after login
                HomeView(username: viewModel.username, token: viewModel.token ?? "")
            }
        }
    }
}

// MARK: - Main App Entry
@main
struct ContentView: App {
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
