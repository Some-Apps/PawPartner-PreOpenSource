import SSToastMessage
import FirebaseAuth
import AlertToast
import SwiftUI
import Kingfisher
import WebKit
import UIKit

struct AnimalView: View {
    // MARK: -Properties
    @StateObject var cardViewModel = CardViewModel()
    @AppStorage("minimumDuration") var minimumDuration = 5

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @ObservedObject var viewModel = AnimalViewModel.shared

    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("lastCatSync") var lastCatSync: String = ""
    @AppStorage("lastDogSync") var lastDogSync: String = ""
    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("feedbackURL") var feedbackURL: String = ""
    @AppStorage("reportProblemURL") var reportProblemURL: String = ""
    @AppStorage("animalType") var animalType = AnimalType.Cat
    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("donationURL") var donationURL: String = ""

    @State private var showAnimalAlert = false
    @State private var screenWidth: CGFloat = 500
    @State private var isImageLoaded = false
    @State private var shouldPresentAnimalAlert = false
    @State private var shouldPresentThankYouView = false
    @State private var showingFeedbackForm = false
    @State private var showingReportForm = false
    @State private var showTutorialQRCode = false
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showIncorrectPassword = false
    @State private var showDonateQRCode = false

    let columns = [
        GridItem(.adaptive(minimum: 330))
    ]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown Version"
    }
    
    var buildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown Build"
    }
    // MARK: -Body
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        showingFeedbackForm = true
                    } label: {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                            Text("Give Feedback")
                        }
                    }
                    .sheet(isPresented: $showingFeedbackForm) {
                        if let feedbackURL = URL(string: "\(feedbackURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: feedbackURL)
                        }
                    }
                    Spacer()
                    if mode != "volunteerAdmin" && mode != "visitorAdmin" {
                        Button("Switch To Admin") {
                            showingPasswordPrompt = true
                        }
                        .sheet(isPresented: $showingPasswordPrompt) {
                            PasswordPromptView(isShowing: $showingPasswordPrompt, passwordInput: $passwordInput, showIncorrectPassword: $showIncorrectPassword) {
                                authViewModel.verifyPassword(password: passwordInput) { isCorrect in
                                    if isCorrect {
                                        // The password is correct. Enable the feature here.
                                        //                                        volunteerMode.toggle()
                                        mode = "volunteerAdmin"
                                        mode = "volunteerAdmin"
                                    } else {
                                        // The password is incorrect. Show an error message.
                                        print("Incorrect Password")
                                        showIncorrectPassword.toggle()
                                        passwordInput = ""
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                    }
                    if mode == "volunteerAdmin" || mode == "visitorAdmin" {
                        Button("Turn Off Admin") {
                            mode = "volunteer"
                        }
                        Spacer()
                    }
                   
                        Button("Switch To Visitor") {
                            if mode == "volunteerAdmin" {
                                mode = "visitorAdmin"
                            } else {
                                mode = "visitor"

                            }
                        }
                        Spacer()
                   
                    
                    Button {
                        showingReportForm = true
                    } label: {
                        HStack {
                            Text("Report Problem")
                            Image(systemName: "exclamationmark.bubble.fill")
                        }
                    }
                    .sheet(isPresented: $showingReportForm) {
                        if let reportProblemURL = URL(string: "\(reportProblemURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: reportProblemURL)
                            
                        }
                    }
                }
                .padding([.horizontal, .top])
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption : .body)
//                if viewModel.cats.filter({ $0.canPlay == true }).count > 1 && viewModel.dogs.filter({ $0.canPlay == true }).count > 1 {
                Picker("Animal Type", selection: $animalType) {
                    Text("Cats").tag(AnimalType.Cat)
                    Text("Dogs").tag(AnimalType.Dog)
                }

                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])
                    .onAppear {
                        print("Current animal type: \(UserDefaults.standard.string(forKey: "animalType") ?? "None")")
                    }
                    .onChange(of: animalType) { newValue in
                        print("Animal type changed to: \(newValue)")
                        UserDefaults.standard.set(newValue.rawValue, forKey: "animalType")
                    }

//                }
                
                ScrollView {
                    switch animalType {
                        case .Dog:
                            AnimalGridView(
                                animals: viewModel.sortedDogs,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )

                        case .Cat:
                            AnimalGridView(
                                animals: viewModel.sortedCats,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )
                        }

                    
                    Button {
                        showTutorialQRCode = true
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Volunteer Tutorial Video")
                        }
                        .padding()
                        .fontWeight(.black)
                    }
                    
                    
                    switch animalType {
                    case .Cat:
                        Text("Last Cat Sync: \(lastCatSync)")
                            .foregroundStyle(Color.secondary)
                    case .Dog:
                        Text("Last Dog Sync: \(lastDogSync)")
                            .foregroundStyle(Color.secondary)
                    }
                    HStack {
                        if latestVersion != "\(appVersion)" {
                            VStack {
                                Text("Your app is not up to date. Please update when convenient.")
                                Button(action: {
                                    if let url = URL(string: updateAppURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {                                    
                                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                            .background(RoundedRectangle(cornerRadius: 20).fill(.customOrange))
                        }
                        VStack {
                            Text("PawPartner is completely free. You can follow us for free on Patreon to get behind-the-scenes updates.")
                            Button {
                                showDonateQRCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                    showDonateQRCode = false
                                }
                            } label: {
                                Label("Patreon", systemImage: "qrcode")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                        .background(RoundedRectangle(cornerRadius: 20).fill(.customBlue))
                    }
                    .padding([.bottom, .horizontal])
                }
//                .onAppear {
//                    if viewModel.cats.count < 1 {
//                        animalType = .Dog
//                    } else if viewModel.dogs.count < 1 {
//                        animalType = .Cat
//                    }
//                }
            }
            // MARK: -Animal Alert
            .overlay(
                AnimalAlertView(animal: viewModel.animal)
                    .opacity(viewModel.showAnimalAlert ? 1 : 0)
            )
        }
        .onChange(of: lastSync) { sync in
            let cache = KingfisherManager.shared.cache
            try? cache.diskStorage.removeAll()
            cache.memoryStorage.removeAll()
            print("Cache removed")
        }
        .onChange(of: viewModel.showLogCreated) { newValue in
            if newValue {
                ThankYouView(animal: viewModel.animal).loadImage { imageLoaded in
                    self.isImageLoaded = imageLoaded
                    self.shouldPresentThankYouView = newValue && imageLoaded
                }
            } else {
                self.isImageLoaded = false
                self.shouldPresentThankYouView = false
            }
        }
        .onChange(of: isImageLoaded) { _ in
            updatePresentationState()
        }
        .onAppear {
            if storedSocietyID == "" && Auth.auth().currentUser?.uid != nil {
                viewModel.fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
                    switch result {
                    case .success(let id):
                        storedSocietyID = id
                        viewModel.listenForSocietyLastSyncUpdate(societyID: id)
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            viewModel.fetchCatData()
            viewModel.fetchDogData()
            viewModel.fetchLatestVersion()
            if storedSocietyID.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                viewModel.postAppVersion(societyID: storedSocietyID, installedVersion: "\(appVersion) (\(buildNumber))")
            }
        }
        .present(isPresented: $shouldPresentThankYouView, type: .alert, animation: .easeIn(duration: 0.2), autohideDuration: 60, closeOnTap: false) {
                ThankYouView(animal: viewModel.animal)
        }
        .toast(isPresenting: $viewModel.showLogTooShort, duration: 3) {
            AlertToast(type: .error(.red), title: minimumDuration == 1 ? "Log must be at least \(minimumDuration) minute" : "Log must be at least \(minimumDuration) minutes")
        }
        .toast(isPresenting: $showIncorrectPassword) {
            AlertToast(type: .error(.red), title: "Incorrect Password")
        }
        .toast(isPresenting: $viewModel.toastAddNote) {
            AlertToast(type: .complete(.green), title: "Note added!")
        }
        .sheet(isPresented: $viewModel.showQRCode) {
            QRCodeView(animal: viewModel.animal)
        }
        .sheet(isPresented: $showDonateQRCode) {
            CustomQRCodeView(url: donationURL)
        }
        .sheet(isPresented: $showTutorialQRCode) {
            Image(uiImage: generateQRCode(from: "https://www.youtube.com/watch?v=\(volunteerVideo)"))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 500)
        }
    }
    // MARK: -Methods
    private func updatePresentationState() {
            shouldPresentThankYouView = viewModel.showLogCreated && isImageLoaded
        }
    
    
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

//#Preview {
//    AnimalView(cardViewModel: CardViewModel(), authViewModel: AuthenticationViewModel(), viewModel: AnimalViewModel(), lastSync: "", latestVersion: "1.0.0", updateAppURL: "google.com", animalType: AnimalType.Cat, storedSocietyID: "abc", volunteerMode: true)
//}


struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct AnimalGridView<Animal>: View where Animal: Identifiable {
    let animals: [Animal]
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let playCheck: (Animal) -> Bool
    let cardView: (Animal) -> CardView

    var body: some View {
        if animals.isEmpty {
            VStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: columns) {
                ForEach(animals, id: \.id) { animal in
                    if playCheck(animal) {
                        cardView(animal)
                            .padding(2)
                    }
                }
            }
            .padding()
        }
    }
}