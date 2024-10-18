import SwiftUI
import Alamofire
import PhotosUI

struct HomeView: View {
    var username: String
    @State var token: String?  // Make token optional to allow setting it to nil
    @State private var showLogoutAlert = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage? = nil  // Explicitly initialize to nil
    
    // State to manage navigation to StartView
    @State private var shouldNavigateToStartView = false

    var body: some View {
        if shouldNavigateToStartView {
            // Navigate to StartView when logout is triggered
            LoginView()
        } else {
            ZStack {
                VStack {
                    // Welcome Text with username
                    Text("Welcome, \(username)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 5)

                    Spacer()

                    // Elegant Photo Picker Button
                    Button(action: {
                        showPhotoPicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")  // Photo picker icon
                                .font(.system(size: 24))
                            Text("Select a Photo")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                    }
                    .sheet(isPresented: $showPhotoPicker) {
                        PhotoPicker(selectedImage: $selectedImage)  // Show the photo picker
                    }
                    .padding(.horizontal, 40)

                    // Display the selected image
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)

                        // Upload Button for the selected image
                        Button(action: {
                            uploadImage(image: image, token: token ?? "")  // Upload the selected image
                        }) {
                            Text("Upload Image")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }

                    Spacer()
                }

                // Logout Button in the bottom-right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 24))
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .alert(isPresented: $showLogoutAlert) {
                            Alert(
                                title: Text("Logout"),
                                message: Text("Are you sure you want to log out?"),
                                primaryButton: .destructive(Text("Logout")) {
                                    logout()  // Trigger logout
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Home")
        }
    }

    struct PhotoPicker: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?

        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.filter = .images  // Only show images
            config.selectionLimit = 1  // Limit to 1 photo selection

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            var parent: PhotoPicker

            init(_ parent: PhotoPicker) {
                self.parent = parent
            }

            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)

                guard let provider = results.first?.itemProvider else { return }

                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                        DispatchQueue.main.async {
                            self?.parent.selectedImage = image as? UIImage
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logout Function
    func logout() {
        // Clear the stored token and other user-related data
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        self.token = nil  // Set the token to nil

        // Navigate to StartView by setting shouldNavigateToStartView to true
        self.shouldNavigateToStartView = true

        print("Logged out successfully.")
    }
}

// MARK: - Upload Image Function for UIImage
func uploadImage(image: UIImage, token: String) {
    let url = "http://localhost:8089/uploadImage"

    // Convert the UIImage to Data (JPEG format)
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        print("Failed to convert UIImage to JPEG data.")
        return
    }

    // Set headers with the Bearer token
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(token)"
    ]

    // Upload the image data using Alamofire
    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(imageData, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
    }, to: url, headers: headers)
    .response { response in
        if let error = response.error {
            print("Error: \(error.localizedDescription)")
            return
        }

        if let responseData = response.data {
            print("Response data: \(String(data: responseData, encoding: .utf8) ?? "")")
        }
    }
}
