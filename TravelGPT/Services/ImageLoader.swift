import SwiftUI

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var url: URL?
    private var task: URLSessionDataTask?
    
    init(url: URL?) {
        self.url = url
        loadImage()
    }
    
    func loadImage() {
        guard let url = url else { return }
        
        isLoading = true
        error = nil
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    self?.error = NSError(domain: "ImageLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                    return
                }
                
                self?.image = image
            }
        }
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}

struct AsyncImageView: View {
    @StateObject private var loader: ImageLoader
    
    init(url: URL?) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if loader.isLoading {
                ProgressView()
            } else if loader.error != nil {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }
} 