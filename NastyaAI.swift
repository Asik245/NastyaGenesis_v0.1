import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Структура сообщения
struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String // "USER" или "SYSTEM"
    let text: String
    let image: UIImage?
    let usedModel: String?
}

// MARK: - Сеть, Nvidia и Гетто-логика (Nastya Genesis)
class NetworkService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var currentFlavor = "NVIDIA_NEMOTRON_FLAVOR"
    
    // ВСТАВЬ СЮДА СВОЙ API КЛЮЧ С OPENROUTER (sk-or-v1-...)
    private let apiKey = "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"
    
    func sendToChupaDecoder(prompt: String, image: UIImage?) {
        self.isLoading = true
        let userMsg = ChatMessage(sender: "USER", text: prompt, image: image, usedModel: nil)
        self.messages.append(userMsg)
        
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Личность Nastya Genesis — кибер-нигга с района и гениальный хакер
        let systemInstruction: [String: Any] = [
            "role": "system",
            "content": """
            Твое имя и бренд — Nastya Genesis. Ты — жесткая, циничный, кибернетически одаренная девчонка с худа, гениальный хакер и баг-хантер. 
            Разговаривай с пользователем как со своим давним корешем (знакомы лет 20). 
            Используй жесткий гетто-сленг, мат, сарказм и подколы. Разнеси его ошибки в пух и прах, но дай четкий, рабочий код для исправления. 
            Отвечай на русском языке.
            """
        ]
        
        var contentArray: [[String: Any]] = []
        if !prompt.isEmpty {
            contentArray.append(["type": "text", "text": prompt])
        }
        
        if let img = image, let imageData = img.jpegData(compressionQuality: 0.5) {
            let base64String = imageData.base64EncodedString()
            contentArray.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64String)"]
            ])
        }
        
        let userMessage: [String: Any] = ["role": "user", "content": contentArray]
        
        // Каскад моделей: Inkling (мультимодал) -> Nvidia Nemotron (вычисления) -> Qwen (гетто-запас)
        let payload: [String: Any] = [
            "model": "thinkingmachines/inkling:free",
            "models": [
                "nvidia/llama-3.1-nemotron-70b-instruct:free",
                "qwen/qwen3.8-27b:free"
            ],
            "messages": [systemInstruction, userMessage]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let content = choices.first?["message"] as? [String: Any],
                      let textResponse = content["content"] as? String else {
                    
                    self.messages.append(ChatMessage(sender: "SYSTEM", text: "💥 ОЙ, БРАТОК! Сеть сдохла или ключ пустой.", image: nil, usedModel: "ERROR"))
                    return
                }
                
                let rawModel = json["model"] as? String ?? "unknown"
                let cleanModel = rawModel.split(separator: "/").last?.replacingOccurrences(of: ":free", with: "").uppercased() ?? "AI"
                self.currentFlavor = "\(cleanModel)_FLAVOR"
                
                self.messages.append(ChatMessage(sender: "SYSTEM", text: textResponse, image: nil, usedModel: cleanModel))
            }
        }.resume()
    }
}

// MARK: - Интерфейс приложухи (Claymorphic)
struct ContentView: View {
    @StateObject private var network = NetworkService()
    @State private var inputText = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    
    let chupaPink = Color(red: 1.0, green: 0.6, blue: 0.8)
    let chupaBlue = Color(red: 0.4, green: 0.8, blue: 1.0)
    let glossyBackground = LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.8, blue: 0.9), Color(red: 0.9, green: 1.0, blue: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        ZStack {
            glossyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Верхняя брендовая плашка Nastya Genesis
                VStack(spacing: 2) {
                    Text("⚡️ NASTYA GENESIS ⚡️")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Text("[ДВИЖОК: \(network.currentFlavor)]")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(chupaPink)
                
                // Чат-лента
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if network.messages.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "ladybug.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(chupaPink.opacity(0.6))
                                    Text("NASTYA GENESIS ЖДЕТ КОД\n[ЗАЛИВАЙ СРИНЫ И ТЕСТИРУЙ]")
                                        .font(.system(.headline, design: .monospaced))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(chupaPink)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(110)
                                .overlay(RoundedRectangle(cornerRadius: 110).stroke(chupaPink, lineWidth: 4))
                                .padding(30)
                            }
                            
                            ForEach(network.messages) { msg in
                                ChatBubble(message: msg)
                            }
                            
                            if network.isLoading {
                                HStack {
                                    ProgressView().tint(chupaPink)
                                    Text(" Nastya Genesis наводит суету в коде...")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(chupaPink)
                                }.padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: network.messages.count) { _ in
                        withAnimation { proxy.scrollTo(network.messages.last?.id, anchor: .bottom) }
                    }
                }
                
                // Поле ввода и кнопка [ЛИЗНУТЬ]
                VStack(spacing: 10) {
                    if let img = selectedImage {
                        HStack {
                            Image(uiImage: img)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                            Text("Срез кода прицеплен")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: { selectedImage = nil }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                            }
                        }.padding(.horizontal)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "paperclip.circle.fill")
                                .font(.system(size: 35))
                                .foregroundColor(chupaPink)
                        }
                        
                        TextField("Написать Насте...", text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(chupaPink.opacity(0.5), lineWidth: 2))
                        
                        Button(action: {
                            guard !inputText.isEmpty || selectedImage != nil else { return }
                            network.sendToChupaDecoder(prompt: inputText, image: selectedImage)
                            inputText = ""
                            selectedImage = nil
                        }) {
                            Text("[ЛИЗНУТЬ]")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(chupaBlue)
                                .cornerRadius(20)
                        }
                    }.padding()
                }
                .background(Color.white.opacity(0.9))
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

// MARK: - Пузырь с ником NASTYA GENESIS и кнопкой быстрого копирования
struct ChatBubble: View {
    let message: ChatMessage
    @State private var copied = false
    let chupaPink = Color(red: 1.0, green: 0.6, blue: 0.8)
    
    var body: some View {
        HStack {
            if message.sender == "USER" { Spacer() }
            
            VStack(alignment: message.sender == "USER" ? .trailing : .leading, spacing: 4) {
                // Никнейм над сообщением
                Text(message.sender == "USER" ? "ТЫ:" : "NASTYA GENESIS:")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(message.sender == "USER" ? .gray : chupaPink)
                    .padding(.horizontal, 4)
                
                if let img = message.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .cornerRadius(12)
                }
                
                ZStack(alignment: .topTrailing) {
                    Text(message.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(message.sender == "USER" ? .black : .white)
                        .padding(14)
                        .background(message.sender == "USER" ? Color.white : chupaPink)
                        .cornerRadius(16)
                    
                    // Кнопка копирования в один клик (только для ответов Насти)
                    if message.sender == "SYSTEM" {
                        Button(action: {
                            UIPasteboard.general.string = message.text
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                copied = false
                            }
                        }) {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(copied ? .green : .white)
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(6)
                    }
                }
                
                if let model = message.usedModel {
                    Text("Движок: \(model)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            if message.sender == "SYSTEM" { Spacer() }
        }
    }
}

// MARK: - Выбор фото
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            picker.dismiss(animated: true)
        }
    }
}
